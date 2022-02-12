/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

/// NSNotificationCenter name indicating a result of a failed log flush attempt. The posted object will be an NSError instance.
FOUNDATION_EXPORT NSNotificationName const FBSDKAppEventsLoggingResultNotification
NS_SWIFT_NAME(AppEventsLoggingResult);
