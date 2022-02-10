/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAppLinkEventPosting.h"
#import "FBSDKMeasurementEvent.h"

NS_ASSUME_NONNULL_BEGIN

/// Provides methods for posting notifications from App Links
@interface FBSDKMeasurementEvent (Internal) <FBSDKAppLinkEventPosting>

- (void)postNotificationForEventName:(NSString *)name
                                args:(NSDictionary<NSString *, id> *)args;

@end

NS_ASSUME_NONNULL_END

#endif
