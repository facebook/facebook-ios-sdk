/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKDeviceLoginViewController.h"

#import <FBSDKLoginKit/FBSDKDeviceLoginManager.h>

@interface FBSDKDeviceLoginViewController () <FBSDKDeviceLoginManagerDelegate>

@property (nonatomic) FBSDKDeviceLoginManager *loginManager;
@property (nonatomic) BOOL isRetry;

@end

@implementation FBSDKDeviceLoginViewController

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [self _cancel];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self _initializeLoginManager];
}

- (void)dealloc
{
  _loginManager.delegate = nil;
  _loginManager = nil;
}

#pragma mark - FBSDKDeviceLoginManagerDelegate

- (void)deviceLoginManager:(FBSDKDeviceLoginManager *)loginManager startedWithCodeInfo:(FBSDKDeviceLoginCodeInfo *)codeInfo
{
  ((FBSDKDeviceDialogView *)self.view).confirmationCode = codeInfo.loginCode;
}

- (void)deviceLoginManager:(FBSDKDeviceLoginManager *)loginManager completedWithResult:(FBSDKDeviceLoginManagerResult *)result error:(NSError *)error
{
  // Go ahead and clear the delegate to avoid double messaging (i.e., since we're dismissing
  // ourselves we don't want a didCancel (from viewDidDisappear) then didFinish.
  id<FBSDKDeviceLoginViewControllerDelegate> delegate = self.delegate;
  self.delegate = nil;

  FBSDKServerConfigurationProvider *provider = [FBSDKServerConfigurationProvider new];
  NSUInteger smartLoginOptions = [provider cachedSmartLoginOptions];
  NSUInteger smartLoginRequireConfirmation = 1 << 1;
  FBSDKAccessToken *token = result.accessToken;
  BOOL requireConfirm = ((smartLoginOptions & smartLoginRequireConfirmation)
    && (token != nil)
    && !_isRetry);
  if (requireConfirm) {
    FBSDKGraphRequest *graphRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                        parameters:@{ @"fields" : @"name" }
                                                                       tokenString:token.tokenString
                                                                           version:nil
                                                                        HTTPMethod:@"GET"];
    [graphRequest startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id graphResult, NSError *graphError) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self _presentConfirmationForDelegate:delegate
                                        token:result.accessToken
                                         name:graphResult[@"name"] ?: token.userID];
      });
    }];
  } else if ([self isNetworkError:error]) {
    NSString *networkErrorMessage = NSLocalizedStringWithDefaultValue(
      @"LoginError.SystemAccount.Network",
      @"FacebookSDK",
      [FBSDKInternalUtility.sharedUtility bundleForStrings],
      @"Unable to connect to Facebook. Check your network connection and try again.",
      @"The user facing error message when the Accounts framework encounters a network error."
    );
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:networkErrorMessage preferredStyle:UIAlertControllerStyleAlert];
    NSString *localizedOK = NSLocalizedStringWithDefaultValue(
      @"ErrorRecovery.Alert.OK",
      @"FacebookSDK",
      [FBSDKInternalUtility.sharedUtility bundleForStrings],
      @"OK",
      @"The title of the label to dismiss the alert when presenting user facing error messages"
    );
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:localizedOK
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction *_Nonnull action) {
                                                       [self dismissViewControllerAnimated:YES completion:^{
                                                         [delegate deviceLoginViewController:self didFailWithError:error];
                                                       }];
                                                     }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
  } else {
    [self dismissViewControllerAnimated:YES completion:^{
      if (result.isCancelled) {
        [self _cancel];
      } else if (token != nil) {
        [self _notifySuccessForDelegate:delegate token:token];
      } else {
        [delegate deviceLoginViewController:self didFailWithError:error];
      }
    }];
  }
}

- (BOOL)isNetworkError:(NSError *)error
{
  NSError *innerError = error.userInfo[NSUnderlyingErrorKey];
  if (innerError && [self isNetworkError:innerError]) {
    return YES;
  }
  switch (error.code) {
    case NSURLErrorTimedOut:
    case NSURLErrorCannotFindHost:
    case NSURLErrorCannotConnectToHost:
    case NSURLErrorNetworkConnectionLost:
    case NSURLErrorDNSLookupFailed:
    case NSURLErrorNotConnectedToInternet:
    case NSURLErrorInternationalRoamingOff:
    case NSURLErrorCallIsActive:
    case NSURLErrorDataNotAllowed:
      return YES;
    default:
      return NO;
  }
}

#pragma mark - Private impl

- (void)_notifySuccessForDelegate:(id<FBSDKDeviceLoginViewControllerDelegate>)delegate
                            token:(FBSDKAccessToken *)token
{
  FBSDKAccessToken.currentAccessToken = token;
  [delegate deviceLoginViewControllerDidFinish:self];
}

- (void)_presentConfirmationForDelegate:(id<FBSDKDeviceLoginViewControllerDelegate>)delegate
                                  token:(FBSDKAccessToken *)token
                                   name:(NSString *)name
{
  NSString *title =
  NSLocalizedStringWithDefaultValue(
    @"SmartLogin.ConfirmationTitle",
    @"FacebookSDK",
    [FBSDKInternalUtility.sharedUtility bundleForStrings],
    @"Confirm Login",
    @"The title for the alert when smart login requires confirmation"
  );
  NSString *cancelTitle =
  NSLocalizedStringWithDefaultValue(
    @"SmartLogin.NotYou",
    @"FacebookSDK",
    [FBSDKInternalUtility.sharedUtility bundleForStrings],
    @"Not you?",
    @"The cancel label for the alert when smart login requires confirmation"
  );
  NSString *continueTitleFormatString =
  NSLocalizedStringWithDefaultValue(
    @"SmartLogin.Continue",
    @"FacebookSDK",
    [FBSDKInternalUtility.sharedUtility bundleForStrings],
    @"Continue as %@",
    @"The format string to continue as <name> for the alert when smart login requires confirmation"
  );
  NSString *continueTitle = [NSString stringWithFormat:continueTitleFormatString, name];
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                           message:title preferredStyle:UIAlertControllerStyleActionSheet];
  [alertController addAction:[UIAlertAction actionWithTitle:continueTitle
                                                      style:UIAlertActionStyleDestructive
                                                    handler:^(UIAlertAction *_Nonnull action) {
                                                      [self dismissViewControllerAnimated:YES completion:^{
                                                        [self _notifySuccessForDelegate:delegate token:token];
                                                      }];
                                                    }]];
  [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle
                                                      style:UIAlertActionStyleCancel
                                                    handler:^(UIAlertAction *_Nonnull action) {
                                                      self->_isRetry = YES;
                                                      FBSDKDeviceDialogView *view = [[FBSDKDeviceDialogView alloc] initWithFrame:self.view.frame];
                                                      view.delegate = self;
                                                      self.view = view;
                                                      [self.view setNeedsDisplay];
                                                      [self _initializeLoginManager];
                                                      // reconnect delegate before since now
                                                      // we are not dismissing.
                                                      self.delegate = delegate;
                                                    }]];
  [self presentViewController:alertController animated:YES completion:NULL];
}

- (void)_initializeLoginManager
{
  // clear any existing login manager
  _loginManager.delegate = nil;
  [_loginManager cancel];
  _loginManager = nil;
  FBSDKServerConfigurationProvider *provider = [FBSDKServerConfigurationProvider new];
  NSUInteger smartLoginOptions = [provider cachedSmartLoginOptions];
  NSUInteger smartLoginRequireConfirmation = 1 << 0;
  BOOL enableSmartLogin = (!_isRetry
    && (smartLoginOptions & smartLoginRequireConfirmation));
  _loginManager = [[FBSDKDeviceLoginManager alloc] initWithPermissions:_permissions
                                                      enableSmartLogin:enableSmartLogin];
  _loginManager.delegate = self;
  _loginManager.redirectURL = self.redirectURL;
  [_loginManager start];
}

- (void)_cancel
{
  [_loginManager cancel];
  [self.delegate deviceLoginViewControllerDidCancel:self];
}

@end
