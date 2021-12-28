/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(WebView)
@protocol FBSDKWebView

@property (nullable, nonatomic, weak) id<WKNavigationDelegate> navigationDelegate;
@property (nonatomic) CGRect frame;
@property (nonatomic) CGRect bounds;

- (nullable WKNavigation *)loadRequest:(NSURLRequest *)request;
- (void)stopLoading;

@end

NS_SWIFT_NAME(WebViewProviding)
@protocol FBSDKWebViewProviding

- (id<FBSDKWebView>)createWebViewWithFrame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END

#endif
