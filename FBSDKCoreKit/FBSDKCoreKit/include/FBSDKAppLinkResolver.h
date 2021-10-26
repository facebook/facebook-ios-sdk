/*
 * Copyright (c) Facebook, Inc. and its affiliates.
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
 Describes the callback for appLinkFromURLInBackground.
 @param appLinks the FBSDKAppLinks representing the deferred App Links
 @param error the error during the request, if any
 */
typedef void (^ FBSDKAppLinksBlock)(NSDictionary<NSURL *, FBSDKAppLink *> *appLinks,
  NSError *_Nullable error)
NS_SWIFT_NAME(AppLinksBlock);

/**

 Provides an implementation of the FBSDKAppLinkResolving protocol that uses the Facebook App Link
 Index API to resolve App Links given a URL. It also provides an additional helper method that can resolve
 multiple App Links in a single call.

 Usage of this type requires a client token. See `[FBSDKSettings setClientToken:]`
 */

NS_SWIFT_NAME(AppLinkResolver)
@interface FBSDKAppLinkResolver : NSObject <FBSDKAppLinkResolving>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Asynchronously resolves App Link data for a given array of URLs.

 @param urls The URLs to resolve into an App Link.
 @param handler The completion block that will return an App Link for the given URL.
 */
- (void)appLinksFromURLs:(NSArray<NSURL *> *)urls handler:(FBSDKAppLinksBlock)handler
    NS_EXTENSION_UNAVAILABLE_IOS("Not available in app extension");

/**
  Allocates and initializes a new instance of FBSDKAppLinkResolver.
 */
+ (instancetype)resolver
  NS_SWIFT_NAME(init());

@end

NS_ASSUME_NONNULL_END

#endif
