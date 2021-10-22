/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKReferralManager+Internal.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ReferralManagerLogger)
@interface FBSDKReferralManagerLogger : NSObject

- (void)logReferralStart;

- (void)logReferralEnd:(nullable FBSDKReferralManagerResult *)result error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END

#endif
