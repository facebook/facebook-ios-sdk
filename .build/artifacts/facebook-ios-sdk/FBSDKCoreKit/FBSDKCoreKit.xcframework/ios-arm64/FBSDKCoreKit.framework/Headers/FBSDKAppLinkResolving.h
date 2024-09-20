/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKAppLink;

/**
 Describes the callback for appLinkFromURLInBackground.
 @param appLink the FBSDKAppLink representing the deferred App Link
 @param error the error during the request, if any
 */
typedef void (^ FBSDKAppLinkBlock)(FBSDKAppLink *_Nullable appLink, NSError *_Nullable error)
NS_SWIFT_NAME(AppLinkBlock);

/**
 Implement this protocol to provide an alternate strategy for resolving
 App Links that may include pre-fetching, caching, or querying for App Link
 data from an index provided by a service provider.
 */
NS_SWIFT_NAME(AppLinkResolving)
@protocol FBSDKAppLinkResolving <NSObject>

/**
 Asynchronously resolves App Link data for a given URL.

 @param url The URL to resolve into an App Link.
 @param handler The completion block that will return an App Link for the given URL.
 */
- (void)appLinkFromURL:(NSURL *)url handler:(FBSDKAppLinkBlock)handler
    NS_EXTENSION_UNAVAILABLE_IOS("Not available in app extension");

@end

NS_ASSUME_NONNULL_END

#endif
