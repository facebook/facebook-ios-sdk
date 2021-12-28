/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKDeviceLoginManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKDeviceLoginManager (Testing)

@property (nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonatomic) id<FBSDKDevicePolling> devicePoller;
@property (nonatomic) id<FBSDKSettings> settings;
@property (nonatomic) id<FBSDKInternalUtility> internalUtility;

- (instancetype)initWithPermissions:(NSArray<NSString *> *)permissions enableSmartLogin:(BOOL)enableSmartLogin
                graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                       devicePoller:(id<FBSDKDevicePolling>)devicePoller
                           settings:(id<FBSDKSettings>)settings
                    internalUtility:(id<FBSDKInternalUtility>)internalUtility;

- (void)_schedulePoll:(NSUInteger)interval;

- (void)setCodeInfo:(FBSDKDeviceLoginCodeInfo *)codeInfo;

- (void)_notifyError:(NSError *)error;

- (void)_notifyToken:(nullable NSString *)tokenString withExpirationDate:(nullable NSDate *)expirationDate withDataAccessExpirationDate:(nullable NSDate *)dataAccessExpirationDate;

- (void)_processError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
