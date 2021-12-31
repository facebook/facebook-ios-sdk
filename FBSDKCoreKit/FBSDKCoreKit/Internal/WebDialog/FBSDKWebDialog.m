/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKWebDialog+Internal.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAccessToken.h"
#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKErrorFactory+Internal.h"
#import "FBSDKErrorReporter.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKLogger.h"
#import "FBSDKSettings.h"
#import "FBSDKWebDialogView.h"
#import "FBSDKWindowFinding.h"

#define FBSDK_WEB_DIALOG_SHOW_ANIMATION_DURATION 0.2
#define FBSDK_WEB_DIALOG_DISMISS_ANIMATION_DURATION 0.3

typedef void (^FBSDKBoolBlock)(BOOL finished);

static FBSDKWebDialog *g_currentDialog = nil;

@interface FBSDKWebDialog () <FBSDKWebDialogViewDelegate>
@end

@interface FBSDKWebDialog ()

@property (class, nonatomic) BOOL hasBeenConfigured;

@property (nullable, nonatomic) UIView *backgroundView;
@property (nullable, nonatomic) FBSDKWebDialogView *dialogView;

@end

@implementation FBSDKWebDialog

// MARK: - Class Dependencies

static BOOL _hasBeenConfigured = NO;

+ (BOOL)hasBeenConfigured
{
  return _hasBeenConfigured;
}

+ (void)setHasBeenConfigured:(BOOL)hasBeenConfigured
{
  _hasBeenConfigured = hasBeenConfigured;
}

static id<FBSDKErrorCreating> _errorFactory;

+ (nullable id<FBSDKErrorCreating>)errorFactory
{
  return _errorFactory;
}

+ (void)setErrorFactory:(nullable id<FBSDKErrorCreating>)errorFactory
{
  _errorFactory = errorFactory;
}

+ (void)configureWithErrorFactory:(id<FBSDKErrorCreating>)errorFactory
{
  self.errorFactory = errorFactory;
  self.hasBeenConfigured = YES;
}

+ (void)configureDefaultClassDependencies
{
  if (self.hasBeenConfigured) {
    return;
  }

  [self configureWithErrorFactory:[[FBSDKErrorFactory alloc] initWithReporter:FBSDKErrorReporter.shared]];
}

#if FBTEST && DEBUG

+ (void)resetClassDependencies
{
  self.errorFactory = nil;
  self.hasBeenConfigured = NO;
}

#endif

// MARK: - Object Lifecycle

- (instancetype)initWithName:(NSString *)name
                  parameters:(nullable NSDictionary<NSString *, id> *)parameters
                       frame:(CGRect)frame
                    delegate:(id<FBSDKWebDialogDelegate>)delegate
                windowFinder:(nullable id<FBSDKWindowFinding>)windowFinder
{
  [self.class configureDefaultClassDependencies];

  if ((self = [super init])) {
    _shouldDeferVisibility = NO;
    _name = [name copy];
    _parameters = [parameters copy];
    _webViewFrame = frame;
    _delegate = delegate;
    _windowFinder = windowFinder;
  }

  return self;
}

- (void)dealloc
{
  _dialogView.delegate = nil;
  [_dialogView removeFromSuperview];
  [_backgroundView removeFromSuperview];
}

// MARK: - Factory Methods

+ (instancetype)dialogWithName:(NSString *)name
                      delegate:(id<FBSDKWebDialogDelegate>)delegate
{
  return [[self alloc] initWithName:name
                         parameters:nil
                              frame:CGRectZero
                           delegate:delegate
                       windowFinder:nil];
}

+ (instancetype)createAndShowWithName:(NSString *)name
                           parameters:(nullable NSDictionary<NSString *, id> *)parameters
                                frame:(CGRect)frame
                             delegate:(id<FBSDKWebDialogDelegate>)delegate
                         windowFinder:(nullable id<FBSDKWindowFinding>)windowFinder
{
  FBSDKWebDialog *dialog = [[self alloc] initWithName:name
                                           parameters:parameters
                                                frame:frame
                                             delegate:delegate
                                         windowFinder:windowFinder];
  [dialog show];
  return dialog;
}

#pragma mark - Public Methods

- (BOOL)show
{
  if (g_currentDialog == self) {
    return NO;
  }
  [g_currentDialog _dismissAnimated:YES];

  NSError *error;
  NSURL *URL = [self _generateURL:&error];
  if (!URL) {
    [self _failWithError:error];
    return NO;
  }

  g_currentDialog = self;

  UIWindow *window = [self.windowFinder findWindow];
  if (!window) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                           logEntry:@"There are no valid windows in which to present this web dialog"];
    error = [self.class.errorFactory unknownErrorWithMessage:@"There are no valid windows in which to present this web dialog"
                                                    userInfo:nil];
    [self _failWithError:error];
    return NO;
  }

  CGRect frame = !CGRectIsEmpty(self.webViewFrame) ? self.webViewFrame : [self _applicationFrameForOrientation];
  _dialogView = [[FBSDKWebDialogView alloc] initWithFrame:frame];

  _dialogView.delegate = self;
  [_dialogView loadURL:URL];

  if (!self.shouldDeferVisibility) {
    [self _showWebView];
  }

  return YES;
}

#pragma mark - FBSDKWebDialogViewDelegate

- (void)webDialogView:(FBSDKWebDialogView *)webDialogView didCompleteWithResults:(NSDictionary<NSString *, id> *)results
{
  [self _completeWithResults:results];
}

- (void)webDialogView:(FBSDKWebDialogView *)webDialogView didFailWithError:(NSError *)error
{
  [self _failWithError:error];
}

- (void)webDialogViewDidCancel:(FBSDKWebDialogView *)webDialogView
{
  [self _cancel];
}

- (void)webDialogViewDidFinishLoad:(FBSDKWebDialogView *)webDialogView
{
  if (self.shouldDeferVisibility) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        if (self->_dialogView) {
          [self _showWebView];
        }
      });
  }
}

#pragma mark - Notifications

- (void)_addObservers
{
  NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
  [nc addObserver:self
         selector:@selector(_deviceOrientationDidChangeNotification:)
             name:UIDeviceOrientationDidChangeNotification
           object:nil];
}

- (void)_deviceOrientationDidChangeNotification:(NSNotification *)notification
{
  BOOL animated = [FBSDKTypeUtility boolValue:notification.userInfo[@"UIDeviceOrientationRotateAnimatedUserInfoKey"]];
  Class CATransactionClass = fbsdkdfl_CATransactionClass();
  CFTimeInterval animationDuration = (animated ? [CATransactionClass animationDuration] : 0.0);
  [self _updateViewsWithScale:1.0 alpha:1.0 animationDuration:animationDuration completion:^(BOOL finished) {
    if (finished) {
      [self->_dialogView setNeedsDisplay];
    }
  }];
}

- (void)_removeObservers
{
  NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
  [nc removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)_cancel
{
  FBSDKWebDialog *dialog = self;
  [self _dismissAnimated:YES]; // may cause the receiver to be released
  [_delegate webDialogDidCancel:dialog];
}

- (void)_completeWithResults:(NSDictionary<NSString *, id> *)results
{
  FBSDKWebDialog *dialog = self;
  [self _dismissAnimated:YES]; // may cause the receiver to be released
  [_delegate webDialog:dialog didCompleteWithResults:results];
}

- (void)_dismissAnimated:(BOOL)animated
{
  [self _removeObservers];
  UIView *backgroundView = _backgroundView;
  _backgroundView = nil;
  FBSDKWebDialogView *dialogView = _dialogView;
  _dialogView.delegate = nil;
  _dialogView = nil;
  void (^didDismiss)(BOOL) = ^(BOOL finished) {
    [backgroundView removeFromSuperview];
    [dialogView removeFromSuperview];
  };
  if (animated) {
    [UIView animateWithDuration:FBSDK_WEB_DIALOG_DISMISS_ANIMATION_DURATION animations:^{
                                                                              dialogView.alpha = 0.0;
                                                                              backgroundView.alpha = 0.0;
                                                                            } completion:didDismiss];
  } else {
    didDismiss(YES);
  }
  if (g_currentDialog == self) {
    g_currentDialog = nil;
  }
}

- (void)_failWithError:(NSError *)error
{
  // defer so that the consumer is guaranteed to have an opportunity to set the delegate before we fail
#ifndef FBTEST
  dispatch_async(dispatch_get_main_queue(), ^{
#endif
  [self _dismissAnimated:YES];
  [self->_delegate webDialog:self didFailWithError:error];
#ifndef FBTEST
});
#endif
}

- (NSURL *)_generateURL:(NSError **)errorRef
{
  NSMutableDictionary<NSString *, id> *parameters = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:parameters setObject:@"touch" forKey:@"display"];
  [FBSDKTypeUtility dictionary:parameters setObject:[NSString stringWithFormat:@"ios-%@", FBSDKSettings.sharedSettings.sdkVersion] forKey:@"sdk"];
  [FBSDKTypeUtility dictionary:parameters setObject:@"fbconnect://success" forKey:@"redirect_uri"];
  [FBSDKTypeUtility dictionary:parameters setObject:FBSDKSettings.sharedSettings.appID forKey:@"app_id"];
  [FBSDKTypeUtility dictionary:parameters
                     setObject:FBSDKAccessToken.currentAccessToken.tokenString
                        forKey:@"access_token"];
  [parameters addEntriesFromDictionary:self.parameters];
  return [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m"
                                                                  path:[@"/dialog/" stringByAppendingString:self.name]
                                                       queryParameters:parameters
                                                                 error:errorRef];
}

- (BOOL)_showWebView
{
  UIWindow *window = [self.windowFinder findWindow];
  if (!window) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                           logEntry:@"There are no valid windows in which to present this web dialog"];
    NSError *error = [self.class.errorFactory unknownErrorWithMessage:@"There are no valid windows in which to present this web dialog"
                                                             userInfo:nil];
    [self _failWithError:error];
    return NO;
  }

  [self _addObservers];

  _backgroundView = [[UIView alloc] initWithFrame:window.bounds];
  _backgroundView.alpha = 0.0;
  _backgroundView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _backgroundView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.8];
    [window addSubview:_backgroundView];
    [window addSubview:_dialogView];

    [_dialogView becomeFirstResponder]; // dismisses the keyboard if it there was another first responder with it
    [self _updateViewsWithScale:0.001 alpha:0.0 animationDuration:0.0 completion:NULL];
    [self _updateViewsWithScale:1.1 alpha:1.0 animationDuration:FBSDK_WEB_DIALOG_SHOW_ANIMATION_DURATION completion:^(BOOL finished1) {
      [self _updateViewsWithScale:0.9 alpha:1.0 animationDuration:FBSDK_WEB_DIALOG_SHOW_ANIMATION_DURATION completion:^(BOOL finished2) {
        [self _updateViewsWithScale:1.0 alpha:1.0 animationDuration:FBSDK_WEB_DIALOG_SHOW_ANIMATION_DURATION completion:NULL];
      }];
    }];
    return YES;
}

- (CGRect)_applicationFrameForOrientation
{
  CGRect applicationFrame = _dialogView.window.screen.bounds;

  UIEdgeInsets insets = UIEdgeInsetsZero;
  if (@available(iOS 11.0, *)) {
    insets = _dialogView.window.safeAreaInsets;
  }

  if (insets.top == 0.0) {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    insets.top = [UIApplication.sharedApplication statusBarFrame].size.height;
    #pragma clang diagnostic pop
  }
  applicationFrame.origin.x += insets.left;
  applicationFrame.origin.y += insets.top;
  applicationFrame.size.width -= insets.left + insets.right;
  applicationFrame.size.height -= insets.top + insets.bottom;

  return applicationFrame;
}

- (void)_updateViewsWithScale:(CGFloat)scale
                        alpha:(CGFloat)alpha
            animationDuration:(CFTimeInterval)animationDuration
                   completion:(FBSDKBoolBlock)completion
{
  CGAffineTransform transform = _dialogView.transform;
  CGRect applicationFrame = !CGRectIsEmpty(self.webViewFrame) ? self.webViewFrame : [self _applicationFrameForOrientation];
  if (scale == 1.0) {
    _dialogView.transform = CGAffineTransformIdentity;
    _dialogView.frame = applicationFrame;
    _dialogView.transform = transform;
  }
  void (^updateBlock)(void) = ^{
    self->_dialogView.transform = transform;
    self->_dialogView.center = CGPointMake(
      CGRectGetMidX(applicationFrame),
      CGRectGetMidY(applicationFrame)
    );
    self->_dialogView.alpha = alpha;
    self->_backgroundView.alpha = alpha;
  };
  if (animationDuration == 0.0) {
    updateBlock();
  } else {
    [UIView animateWithDuration:animationDuration animations:updateBlock completion:completion];
  }
}

@end

#endif
