/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKLoggingBehavior.h>

NS_ASSUME_NONNULL_BEGIN

/**

 Simple logging utility for conditionally logging strings and then emitting them
 via NSLog().

 @unsorted

 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(Logger)
@interface FBSDKLogger : NSObject

- (instancetype)init DEPRECATED_MSG_ATTRIBUTE("`init` is deprecated and will be removed in the next major release. Please use one of the other available initializers");
+ (instancetype)new DEPRECATED_MSG_ATTRIBUTE("`new` is deprecated and will be removed in the next major release. Please use one of the other available initializers");

// Simple helper to write a single log entry, based upon whether the behavior matches a specified on.
+ (void)singleShotLogEntry:(FBSDKLoggingBehavior)loggingBehavior
                  logEntry:(NSString *)logEntry;

@end

NS_ASSUME_NONNULL_END
