/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKBackgroundEventLogging.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol FBSDKInfoDictionaryProviding;
@protocol FBSDKEventLogging;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_BackgroundEventLogger)
@interface FBSDKBackgroundEventLogger : NSObject <FBSDKBackgroundEventLogging>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithInfoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
                                   eventLogger:(id<FBSDKEventLogging>)eventLogger NS_DESIGNATED_INITIALIZER;

- (void)logBackgroundRefreshStatus:(UIBackgroundRefreshStatus)status;

@end

NS_ASSUME_NONNULL_END

#endif
