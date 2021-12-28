/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKWebViewAppLinkResolverWebViewDelegate : NSObject <WKNavigationDelegate>

@property (nonatomic, copy) void (^didFinishLoad)(WKWebView *webView);
@property (nonatomic, copy) void (^didFailLoadWithError)(WKWebView *webView, NSError *error);
@property (nonatomic, assign) BOOL hasLoaded;

@end

NS_ASSUME_NONNULL_END

#endif
