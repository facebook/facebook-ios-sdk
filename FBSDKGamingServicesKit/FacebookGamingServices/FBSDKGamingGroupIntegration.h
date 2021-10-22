/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FacebookGamingServices/FBSDKGamingServiceCompletionHandler.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(GamingGroupIntegration)
@interface FBSDKGamingGroupIntegration : NSObject

+ (void)openGroupPageWithCompletionHandler:(FBSDKGamingServiceCompletionHandler _Nonnull)completionHandler;

@end

NS_ASSUME_NONNULL_END
