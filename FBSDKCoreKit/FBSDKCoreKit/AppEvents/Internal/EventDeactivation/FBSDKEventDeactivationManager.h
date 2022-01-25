/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKAppEventName.h>
#import <FBSDKCoreKit/FBSDKAppEventParameterName.h>

#import "FBSDKAppEventsParameterProcessing.h"
#import "FBSDKEventsProcessing.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(EventDeactivationManager)
@interface FBSDKEventDeactivationManager : NSObject <FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing>

- (void)enable;
- (void)processEvents:(NSMutableArray<NSDictionary<NSString *, id> *> *)events;
- (nullable NSDictionary<FBSDKAppEventParameterName, id> *)processParameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters
                                                                   eventName:(FBSDKAppEventName)eventName;

@end

NS_ASSUME_NONNULL_END
