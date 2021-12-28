/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKEventBinding.h"

@protocol FBSDKEventLogging;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKEventBinding (Testing)

@property (nonnull, nonatomic) id<FBSDKEventLogging> eventLogger;

+ (NSString *)findParameterOfPath:(NSArray *)path
                         pathType:(NSString *)pathType
                       sourceView:(UIView *)sourceView;

@end

NS_ASSUME_NONNULL_END
