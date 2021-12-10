/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKRestrictiveDataFilterManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKRestrictiveDataFilterManager (Testing)

@property (nonatomic) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;

- (nullable NSString *)getMatchedDataTypeWithEventName:(NSString *)eventName
                                              paramKey:(NSString *)paramKey;
@end

NS_ASSUME_NONNULL_END
