/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKAppLinkResolving.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A reference implementation for an App Link resolver that uses a hidden WKWebView
 to parse the HTML containing App Link metadata.
 */
NS_SWIFT_NAME(WebViewAppLinkResolver)
@interface FBSDKWebViewAppLinkResolver : NSObject <FBSDKAppLinkResolving>

/**
 Gets the instance of a FBSDKWebViewAppLinkResolver.
 */
@property (class, nonatomic, readonly, strong) FBSDKWebViewAppLinkResolver *sharedInstance
NS_SWIFT_NAME(shared);

@end

NS_ASSUME_NONNULL_END

#endif
