/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

@protocol FBSDKImpressionLoggerFactory;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(ImpressionLoggingButton)
@interface FBSDKImpressionLoggingButton : UIButton

+ (void)configureWithImpressionLoggerFactory:(id<FBSDKImpressionLoggerFactory>)impressionLoggerFactory
NS_SWIFT_NAME(configure(impressionLoggerFactory:));

@end

NS_ASSUME_NONNULL_END
