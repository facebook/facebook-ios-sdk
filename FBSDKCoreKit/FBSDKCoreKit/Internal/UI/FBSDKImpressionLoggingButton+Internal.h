/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKImpressionLoggingButton.h>

#import "FBSDKImpressionLoggerFactoryProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKImpressionLoggingButton (Internal)

@property (class, nullable, nonatomic, readonly) id<FBSDKImpressionLoggerFactory> impressionLoggerFactory;

+ (void)configureWithImpressionLoggerFactory     :(id<FBSDKImpressionLoggerFactory>)impressionLoggerFactory
  NS_SWIFT_NAME(configure(impressionLoggerFactory:));

#if DEBUG && FBTEST
+ (void)resetClassDependencies;
#endif

@end

NS_ASSUME_NONNULL_END
