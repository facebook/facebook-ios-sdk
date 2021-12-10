/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBAEMKit/FBAEMKit.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(SKAdNetworkReporter)
@interface FBSDKSKAdNetworkReporter : NSObject <FBSKAdNetworkReporting>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)enable;

- (void)checkAndRevokeTimer;

- (void)recordAndUpdateEvent:(NSString *)event
                    currency:(nullable NSString *)currency
                       value:(nullable NSNumber *)value;

- (BOOL)shouldCutoff;

- (BOOL)isReportingEvent:(NSString *)event;

@end

NS_ASSUME_NONNULL_END

#endif
