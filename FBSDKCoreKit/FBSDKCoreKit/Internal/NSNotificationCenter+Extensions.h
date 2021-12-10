/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKNotificationProtocols.h"

NS_ASSUME_NONNULL_BEGIN

// Default conformance to NotificationPosting and NotificationObserving
@interface NSNotificationCenter (NotificationProtocolsConformance) <FBSDKNotificationPosting, FBSDKNotificationObserving>
@end

NS_ASSUME_NONNULL_END
