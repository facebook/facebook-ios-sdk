/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAppLinkTargetProtocol.h"
#import "FBSDKAppLinkProtocol.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppLinkCreating)
@protocol FBSDKAppLinkCreating

- (id<FBSDKAppLink>)createAppLinkWithSourceURL:(nullable NSURL *)sourceURL
                                       targets:(NSArray<id<FBSDKAppLinkTarget>> *)targets
                                        webURL:(nullable NSURL *)webURL
                              isBackToReferrer:(BOOL)isBackToReferrer
NS_SWIFT_NAME(createAppLink(sourceURL:targets:webURL:isBackToReferrer:));

@end

NS_ASSUME_NONNULL_END

#endif
