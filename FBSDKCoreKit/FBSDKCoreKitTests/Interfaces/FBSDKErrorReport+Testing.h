/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKErrorReporter.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKErrorReporter (Testing)

- (NSArray<NSDictionary<NSString *, id> *> *)loadErrorReports;
- (void)uploadErrors;
- (void)reset;

@end

NS_ASSUME_NONNULL_END
