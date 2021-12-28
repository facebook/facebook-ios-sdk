/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAppLink.h"
#import "FBSDKAppLinkProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAppLink (Internal) <FBSDKAppLink>

+ (instancetype)appLinkWithSourceURL:(nullable NSURL *)sourceURL
                             targets:(NSArray<id<FBSDKAppLinkTarget>> *)targets
                              webURL:(nullable NSURL *)webURL
                    isBackToReferrer:(BOOL)isBackToReferrer;

@end

NS_ASSUME_NONNULL_END

#endif
