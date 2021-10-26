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
#import <FBSDKCoreKit/FBSDKGraphRequest.h>
NS_ASSUME_NONNULL_BEGIN

/**
 Class responsible for generating the appropriate FBSDKGraphRequest for a given set of urls
 */
NS_SWIFT_NAME(AppLinkResolverRequestBuilder)
@interface FBSDKAppLinkResolverRequestBuilder : NSObject

/**
 Generates the FBSDKGraphRequest

 @param urls The URLs to build the requests for
 */
- (FBSDKGraphRequest *_Nonnull)requestForURLs:(NSArray<NSURL *> *_Nonnull)urls
    NS_EXTENSION_UNAVAILABLE_IOS("Not available in app extension");

- (NSString *_Nullable)getIdiomSpecificField
    NS_EXTENSION_UNAVAILABLE_IOS("Not available in app extension");
@end

NS_ASSUME_NONNULL_END

#endif
