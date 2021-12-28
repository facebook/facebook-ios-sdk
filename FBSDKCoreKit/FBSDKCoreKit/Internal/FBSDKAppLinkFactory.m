/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAppLinkFactory.h"

#import "FBSDKAppLink+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKAppLinkFactory

- (id<FBSDKAppLink>)createAppLinkWithSourceURL:(nullable NSURL *)sourceURL
                                       targets:(NSArray<id<FBSDKAppLinkTarget>> *)targets
                                        webURL:(nullable NSURL *)webURL
                              isBackToReferrer:(BOOL)isBackToReferrer
{
  return [FBSDKAppLink appLinkWithSourceURL:sourceURL
                                    targets:targets
                                     webURL:webURL
                           isBackToReferrer:isBackToReferrer];
}

@end

NS_ASSUME_NONNULL_END

#endif
