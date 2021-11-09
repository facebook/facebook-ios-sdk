/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKDeviceLoginManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKDeviceLoginManager (Testing)

- (instancetype)initWithPermissions:(NSArray<NSString *> *)permissions enableSmartLogin:(BOOL)enableSmartLogin
                graphRequestFactory:(nonnull id<FBSDKGraphRequestFactory>)graphRequestConnectionFactory
                       devicePoller:(id<FBSDKDevicePolling>)poller;

- (void)_schedulePoll:(NSUInteger)interval;

- (void)setCodeInfo:(FBSDKDeviceLoginCodeInfo *)codeInfo;

- (void)_notifyError:(NSError *)error;

- (void)_notifyToken:(nullable NSString *)tokenString withExpirationDate:(nullable NSDate *)expirationDate withDataAccessExpirationDate:(nullable NSDate *)dataAccessExpirationDate;

- (void)_processError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
