/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKAppEventName.h>
#import <FBSDKCoreKit/FBSDKAppEventParameterName.h>
#import <FBSDKCoreKit/FBSDKAppEventsParameterProcessing.h>
#import <FBSDKCoreKit/FBSDKEventsProcessing.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_EventDeactivationManager)
@interface FBSDKEventDeactivationManager : NSObject <FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing>

- (void)enable;
- (void)processEvents:(NSMutableArray<NSDictionary<NSString *, id> *> *)events;
- (nullable NSDictionary<FBSDKAppEventParameterName, id> *)processParameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters
                                                                   eventName:(FBSDKAppEventName)eventName;

@end

NS_ASSUME_NONNULL_END
