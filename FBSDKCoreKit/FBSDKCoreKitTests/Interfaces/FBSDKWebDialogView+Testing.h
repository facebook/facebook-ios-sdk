/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKWebDialogView+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKWebDialogView (Testing) <WKNavigationDelegate>

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nullable, nonatomic, strong) id<FBSDKWebView> webView;

+ (void)resetClassDependencies;

@end

NS_ASSUME_NONNULL_END
