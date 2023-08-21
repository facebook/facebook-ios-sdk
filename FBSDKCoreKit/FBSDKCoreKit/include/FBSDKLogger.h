/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKLogging.h>
#import <FBSDKCoreKit/FBSDKLoggingBehavior.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Simple logging utility for conditionally logging strings and then emitting them
 via NSLog().

 @unsorted

 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_Logger)
@interface FBSDKLogger : NSObject <FBSDKLogging>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// Simple helper to write a single log entry, based upon whether the behavior matches a specified on.
+ (void)singleShotLogEntry:(FBSDKLoggingBehavior)loggingBehavior
                  logEntry:(NSString *)logEntry;

@end

NS_ASSUME_NONNULL_END
