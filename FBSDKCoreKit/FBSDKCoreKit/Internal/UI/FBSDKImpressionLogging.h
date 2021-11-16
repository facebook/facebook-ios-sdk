/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ImpressionLogging)
@protocol FBSDKImpressionLogging

- (void)logImpressionWithIdentifier:(NSString *)identifier
                         parameters:(nullable NSDictionary<NSString *, id> *)parameters;

@end

NS_ASSUME_NONNULL_END
