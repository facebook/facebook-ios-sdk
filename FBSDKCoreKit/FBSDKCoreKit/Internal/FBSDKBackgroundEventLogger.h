/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "FBSDKBackgroundEventLogging.h"

@protocol FBSDKInfoDictionaryProviding;
@protocol FBSDKEventLogging;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(BackgroundEventLogger)
@interface FBSDKBackgroundEventLogger : NSObject <FBSDKBackgroundEventLogging>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithInfoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
                                   eventLogger:(id<FBSDKEventLogging>)eventLogger NS_DESIGNATED_INITIALIZER;

- (void)logBackgroundRefreshStatus:(UIBackgroundRefreshStatus)status;

@end

NS_ASSUME_NONNULL_END

#endif
