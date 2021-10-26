/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKGamingServiceCompletionHandler.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FBSDKGamingServiceType) {
  FBSDKGamingServiceTypeFriendFinder,
  FBSDKGamingServiceTypeMediaAsset,
  FBSDKGamingServiceTypeCommunity,
}
NS_SWIFT_NAME(GamingServiceType);

NS_SWIFT_NAME(GamingServiceController)
@interface FBSDKGamingServiceController : NSObject <FBSDKURLOpening>

/**
Used to link to gaming services on Facebook.

@param completion a callback that is fired once the user returns to the
 caller app or an error ocurrs
@param pendingResult an optional object that will be passed to the completion handler as 'result'
*/
- (instancetype)initWithServiceType:(FBSDKGamingServiceType)serviceType
                  completionHandler:(FBSDKGamingServiceResultCompletion)completion
                      pendingResult:(id)pendingResult;

- (void)callWithArgument:(nullable NSString *)argument;

@end

NS_ASSUME_NONNULL_END
