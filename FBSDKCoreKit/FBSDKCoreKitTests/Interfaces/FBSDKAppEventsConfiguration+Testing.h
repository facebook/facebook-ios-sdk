/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppEventsConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAppEventsConfiguration (Testing)

+ (FBSDKAppEventsConfiguration *)defaultConfiguration;

- (void)setDefaultATEStatus:(FBSDKAdvertisingTrackingStatus)status;

// UNCRUSTIFY_FORMAT_OFF
- (instancetype)initWithDefaultATEStatus:(FBSDKAdvertisingTrackingStatus)defaultATEStatus
           advertiserIDCollectionEnabled:(BOOL)advertiserIDCollectionEnabled
                  eventCollectionEnabled:(BOOL)eventCollectionEnabled
NS_SWIFT_NAME(init(defaultATEStatus:advertiserIDCollectionEnabled:eventCollectionEnabled:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END
