/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKWebDialogView.h"
#import "FBSDKWebViewFactory.h"
#import "FBSDKWebViewProviding.h"
#import "WKWebView+WebViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKWebDialogView (Testing) <WKNavigationDelegate>

@property (class, nullable, nonatomic, readonly, strong) id<FBSDKWebViewProviding> webViewProvider;
@property (class, nullable, nonatomic, readonly, strong) id<FBSDKURLOpener> urlOpener;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nullable, nonatomic, strong) id<FBSDKWebView> webView;

+ (void)reset;

@end

NS_ASSUME_NONNULL_END
