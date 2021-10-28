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

NS_SWIFT_NAME(Logging)
@protocol FBSDKLogging

@property (nonatomic, readonly, copy) NSString *contents;
@property (nonatomic, readonly, copy) FBSDKLoggingBehavior loggingBehavior;

- (instancetype)initWithLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior;

+ (void)singleShotLogEntry:(FBSDKLoggingBehavior)loggingBehavior
                  logEntry:(NSString *)logEntry;

- (void)logEntry:(NSString *)logEntry;

@end

NS_ASSUME_NONNULL_END
