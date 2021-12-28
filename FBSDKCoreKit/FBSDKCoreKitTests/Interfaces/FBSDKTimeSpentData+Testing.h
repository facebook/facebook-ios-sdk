/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKTimeSpentData.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKTimeSpentData ()

@property (nonatomic, weak) id<FBSDKEventLogging> eventLogger;
@property (nonnull, nonatomic) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (nonatomic) NSString *sourceApplication;
@property (nonatomic) BOOL isOpenedFromAppLink;

- (NSString *)getSourceApplication;
- (void)resetSourceApplication;
- (NSDictionary<NSString *, id> *)appEventsParametersForDeactivate;

@end

NS_ASSUME_NONNULL_END
