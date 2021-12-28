/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@protocol FBSDKAppEventsParameterProcessing;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(IntegrityParametersProcessorProvider)
@protocol FBSDKIntegrityParametersProcessorProvider

@property (nullable, nonatomic) id<FBSDKAppEventsParameterProcessing> integrityParametersProcessor;

@end

NS_ASSUME_NONNULL_END
