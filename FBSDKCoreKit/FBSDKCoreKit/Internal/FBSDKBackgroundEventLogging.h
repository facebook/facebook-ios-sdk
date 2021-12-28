/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKInfoDictionaryProviding;
@protocol FBSDKEventLogging;

NS_SWIFT_NAME(BackgroundEventLogging)
@protocol FBSDKBackgroundEventLogging

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithInfoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
                                   eventLogger:(id<FBSDKEventLogging>)eventLogger;

- (void)logBackgroundRefreshStatus:(UIBackgroundRefreshStatus)status;

@end

NS_ASSUME_NONNULL_END

#endif
