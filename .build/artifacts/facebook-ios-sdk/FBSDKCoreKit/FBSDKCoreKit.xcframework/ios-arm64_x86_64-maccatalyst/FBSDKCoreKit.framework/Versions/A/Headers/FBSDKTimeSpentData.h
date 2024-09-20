/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKSourceApplicationTracking.h>
#import <FBSDKCoreKit/FBSDKTimeSpentRecording.h>
#import <Foundation/Foundation.h>

@protocol FBSDKEventLogging;
@protocol FBSDKServerConfigurationProviding;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
// Class to encapsulate persisting of time spent data collected by [FBSDKAppEvents.shared activateApp].  The activate app App Event is
// logged when restore: is called with sufficient time since the last deactivation.
NS_SWIFT_NAME(_TimeSpentData)
@interface FBSDKTimeSpentData : NSObject <FBSDKSourceApplicationTracking, FBSDKTimeSpentRecording>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithEventLogger:(id<FBSDKEventLogging>)eventLogger
        serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider;

- (void)setSourceApplication:(nullable NSString *)sourceApplication openURL:(nullable NSURL *)url;
- (void)setSourceApplication:(nullable NSString *)sourceApplication isFromAppLink:(BOOL)isFromAppLink;
- (void)registerAutoResetSourceApplication;
- (void)suspend;
- (void)restore:(BOOL)calledFromActivateApp;

@end

NS_ASSUME_NONNULL_END
