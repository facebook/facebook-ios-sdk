/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKAppEventName.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(RestrictiveData)
@interface FBSDKRestrictiveData : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithEventName:(FBSDKAppEventName)eventName params:(id)params;

@property (nonatomic, readonly, copy) FBSDKAppEventName eventName;
@property (nullable, nonatomic, readonly, copy) NSDictionary<NSString *, NSString *> *restrictiveParams;
@property (nullable, nonatomic, readonly, copy) NSArray<NSString *> *deprecatedParams;
@property (nonatomic, readonly, assign) BOOL deprecatedEvent;

@end

NS_ASSUME_NONNULL_END
