/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKBackgroundEventLogger.h"
#import "FBSDKBackgroundEventLogging.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKBackgroundEventLogger (Testing)

@property (nonnull, nonatomic, readonly) id<FBSDKInfoDictionaryProviding> infoDictionaryProvider;
@property (nonnull, nonatomic, readonly) id<FBSDKEventLogging> eventLogger;

- (BOOL)_isNewBackgroundRefresh;

@end

NS_ASSUME_NONNULL_END
