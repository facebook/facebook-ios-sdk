/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKAppEventsParameterProcessing.h"
#import "FBSDKEventsProcessing.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(EventDeactivationManager)
@interface FBSDKEventDeactivationManager : NSObject <FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing>

- (void)enable;
- (void)processEvents:(NSMutableArray<NSDictionary<NSString *, id> *> *)events;
- (nullable NSDictionary<NSString *, id> *)processParameters:(nullable NSDictionary<NSString *, id> *)parameters
                                                   eventName:(NSString *)eventName;

@end

NS_ASSUME_NONNULL_END
