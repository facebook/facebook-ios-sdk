/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKErrorRecoveryConfiguration.h"

@protocol FBSDKGraphRequest;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ErrorConfigurationProtocol)
@protocol FBSDKErrorConfiguration

- (nullable FBSDKErrorRecoveryConfiguration *)recoveryConfigurationForCode:(nullable NSString *)code
                                                                   subcode:(nullable NSString *)subcode
                                                                   request:(id<FBSDKGraphRequest>)request;

@end

NS_ASSUME_NONNULL_END
