/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKLoggerFactory.h"

#import <Foundation/Foundation.h>

#import "FBSDKLogger+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKLoggerFactory

- (id<FBSDKLogging>)createLoggerWithLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior
{
  return [[FBSDKLogger alloc] initWithLoggingBehavior:loggingBehavior];
}

@end

NS_ASSUME_NONNULL_END
