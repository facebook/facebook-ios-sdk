/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKWebDialogView+Internal.h"

#import <WebKit/WebKit.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKCloseIcon.h"
#import "FBSDKInternalURLOpener.h"
#import "FBSDKSafeCast.h"
#import "FBSDKWebViewProviding.h"

#define FBSDK_WEB_DIALOG_VIEW_BORDER_WIDTH 10.0

@interface FBSDKWebDialogView () <WKNavigationDelegate>

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, strong) id<FBSDKWebView> webView;

@end

@implementation FBSDKWebDialogView

static id<FBSDKWebViewProviding> _webViewProvider;
static id<FBSDKInternalURLOpener> _urlOpener;
static id<FBSDKErrorCreating> _errorFactory;

+ (void)configureWithWebViewProvider:(id<FBSDKWebViewProviding>)webViewProvider
                           urlOpener:(id<FBSDKInternalURLOpener>)urlOpener
                        errorFactory:(id<FBSDKErrorCreating>)errorFactory;
{
  _webViewProvider = webViewProvider;
  _urlOpener = urlOpener;
  _errorFactory = errorFactory;
}

+ (nullable id<FBSDKWebViewProviding>)webViewProvider
{
  return _webViewProvider;
}

+ (void)setWebViewProvider:(id<FBSDKWebViewProviding>)webViewProvider
{
  _webViewProvider = webViewProvider;
}

+ (nullable id<FBSDKInternalURLOpener>)urlOpener
{
  return _urlOpener;
}

+ (void)setUrlOpener:(nullable id<FBSDKInternalURLOpener>)urlOpener
{
  _urlOpener = urlOpener;
}

+ (nullable id<FBSDKErrorCreating>)errorFactory
{
  return _errorFactory;
}

+ (void)setErrorFactory:(nullable id<FBSDKErrorCreating>)errorFactory
{
  _errorFactory = errorFactory;
}

#pragma mark - Object Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    self.backgroundColor = UIColor.clearColor;
    self.opaque = NO;

    _webView = [self.class.webViewProvider createWebViewWithFrame:CGRectZero];
    _webView.navigationDelegate = self;

    // Since we cannot constrain the webview protocol to be a UIView subclass
    // perform a check here to make sure it can be cast to a UIView
    UIView *webView = _FBSDKCastToClassOrNilUnsafeInternal(_webView, UIView.class);
    if (!webView) {
      return self;
    }

    [self addSubview:webView];

    _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *closeImage = [[FBSDKCloseIcon new] imageWithSize:CGSizeMake(29.0, 29.0)];
    [_closeButton setImage:closeImage forState:UIControlStateNormal];
    [_closeButton setTitleColor:[UIColor colorWithRed:167.0 / 255.0
                                                green:184.0 / 255.0
                                                 blue:216.0 / 255.0
                                                alpha:1.0] forState:UIControlStateNormal];
    [_closeButton setTitleColor:UIColor.whiteColor forState:UIControlStateHighlighted];
    _closeButton.showsTouchWhenHighlighted = YES;
    [_closeButton sizeToFit];
    [self addSubview:_closeButton];
    [_closeButton addTarget:self action:@selector(_close:) forControlEvents:UIControlEventTouchUpInside];

    UIActivityIndicatorViewStyle style;
    if (@available(iOS 13.0, *)) {
      style = UIActivityIndicatorViewStyleLarge;
    } else {
      #pragma clang diagnostic push
      #pragma clang diagnostic ignored "-Wdeprecated-declarations"
      style = UIActivityIndicatorViewStyleWhiteLarge;
      #pragma clang diagnostic pop
    }
    _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
    _loadingView.color = UIColor.grayColor;
    _loadingView.hidesWhenStopped = YES;
    [webView addSubview:_loadingView];
  }
  return self;
}

- (void)dealloc
{
  self.webView.navigationDelegate = nil;
}

#pragma mark - Public Methods

- (void)loadURL:(NSURL *)URL
{
  [self.loadingView startAnimating];
  [self.webView loadRequest:[NSURLRequest requestWithURL:URL]];
}

- (void)stopLoading
{
  [self.webView stopLoading];
  [self.loadingView stopAnimating];
}

#pragma mark - Layout

- (void)drawRect:(CGRect)rect
{
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSaveGState(context);
  [self.backgroundColor setFill];
  CGContextFillRect(context, self.bounds);
  [UIColor.blackColor setStroke];
  CGContextSetLineWidth(context, 1.0 / self.layer.contentsScale);
  CGContextStrokeRect(context, self.webView.frame);
  CGContextRestoreGState(context);
  [super drawRect:rect];
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  CGRect bounds = self.bounds;
  if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
    CGFloat horizontalInset = CGRectGetWidth(bounds) * 0.2;
    CGFloat verticalInset = CGRectGetHeight(bounds) * 0.2;
    UIEdgeInsets iPadInsets = UIEdgeInsetsMake(verticalInset, horizontalInset, verticalInset, horizontalInset);
    bounds = UIEdgeInsetsInsetRect(bounds, iPadInsets);
  }
  UIEdgeInsets webViewInsets = UIEdgeInsetsMake(
    FBSDK_WEB_DIALOG_VIEW_BORDER_WIDTH,
    FBSDK_WEB_DIALOG_VIEW_BORDER_WIDTH,
    FBSDK_WEB_DIALOG_VIEW_BORDER_WIDTH,
    FBSDK_WEB_DIALOG_VIEW_BORDER_WIDTH
  );
  self.webView.frame = CGRectIntegral(UIEdgeInsetsInsetRect(bounds, webViewInsets));

  CGRect webViewBounds = self.webView.bounds;
  self.loadingView.center = CGPointMake(CGRectGetMidX(webViewBounds), CGRectGetMidY(webViewBounds));

  if (CGRectGetHeight(webViewBounds) == 0.0) {
    self.closeButton.alpha = 0.0;
  } else {
    self.closeButton.alpha = 1.0;
    CGRect closeButtonFrame = self.closeButton.bounds;
    closeButtonFrame.origin = bounds.origin;
    self.closeButton.frame = CGRectIntegral(closeButtonFrame);
  }
}

#pragma mark - Actions

- (void)_close:(id)sender
{
  [self.delegate webDialogViewDidCancel:self];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
  [self.loadingView stopAnimating];

  // 102 == WebKitErrorFrameLoadInterruptedByPolicyChange
  // NSURLErrorCancelled == "Operation could not be completed", note NSURLErrorCancelled occurs when the user clicks
  // away before the page has completely loaded, if we find cases where we want this to result in dialog failure
  // (usually this just means quick-user), then we should add something more robust here to account for differences in
  // application needs
  if (!(([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled)
        || ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102))) {
    [self.delegate webDialogView:self didFailWithError:error];
  }
}

- (void)                  webView:(WKWebView *)webView
  decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                  decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
  NSURL *URL = navigationAction.request.URL;

  if ([URL.scheme isEqualToString:@"fbconnect"]) {
    NSMutableDictionary<NSString *, id> *parameters = [[FBSDKBasicUtility dictionaryWithQueryString:URL.query] mutableCopy];
    [parameters addEntriesFromDictionary:[FBSDKBasicUtility dictionaryWithQueryString:URL.fragment]];
    if ([URL.resourceSpecifier hasPrefix:@"//cancel"]) {
      NSInteger errorCode = [FBSDKTypeUtility integerValue:parameters[@"error_code"]];
      if (errorCode) {
        NSString *errorMessage = [FBSDKTypeUtility coercedToStringValue:parameters[@"error_msg"]];
        NSError *error = [self.class.errorFactory errorWithCode:errorCode
                                                       userInfo:nil
                                                        message:errorMessage
                                                underlyingError:nil];
        [self.delegate webDialogView:self didFailWithError:error];
      } else {
        [self.delegate webDialogViewDidCancel:self];
      }
    } else {
      [self.delegate webDialogView:self didCompleteWithResults:parameters];
    }
    decisionHandler(WKNavigationActionPolicyCancel);
  } else if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
    if (@available(iOS 10.0, *)) {
      [self.class.urlOpener openURL:URL options:@{} completionHandler:^(BOOL success) {
        decisionHandler(WKNavigationActionPolicyCancel);
      }];
    } else {
      [self.class.urlOpener openURL:URL];
      decisionHandler(WKNavigationActionPolicyCancel);
    }
  } else {
    decisionHandler(WKNavigationActionPolicyAllow);
  }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
  [self.loadingView stopAnimating];
  [self.delegate webDialogViewDidFinishLoad:self];
}

#if DEBUG && FBTEST

+ (void)resetClassDependencies
{
  self.webViewProvider = nil;
  self.urlOpener = nil;
  self.errorFactory = nil;
}

#endif

@end

#endif
