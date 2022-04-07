/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKErrorFactory.h>

#import "FBSDKErrorReporting.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKErrorFactory ()

@property (class, nullable, nonatomic) id<FBSDKErrorReporting> defaultReporter;
@property (nullable, nonatomic) id<FBSDKErrorReporting> reporter;

// UNCRUSTIFY_FORMAT_OFF
+ (void)configureWithDefaultReporter:(id<FBSDKErrorReporting>)defaultReporter
NS_SWIFT_NAME(configure(defaultReporter:));
// UNCRUSTIFY_FORMAT_ON

#if DEBUG
+ (void)resetClassDependencies;
#endif

- (instancetype)initWithReporter:(id<FBSDKErrorReporting>)reporter;

@end

NS_ASSUME_NONNULL_END
