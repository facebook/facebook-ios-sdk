/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKErrorCreating.h>
#import <FBSDKCoreKit/FBSDKErrorReporting.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ErrorFactory)
@interface FBSDKErrorFactory : NSObject <FBSDKErrorCreating>

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
- (instancetype)initWithReporter:(id<FBSDKErrorReporting>)reporter;

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
// UNCRUSTIFY_FORMAT_OFF
+ (void)configureWithDefaultReporter:(id<FBSDKErrorReporting>)defaultReporter
NS_SWIFT_NAME(configure(defaultReporter:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END
