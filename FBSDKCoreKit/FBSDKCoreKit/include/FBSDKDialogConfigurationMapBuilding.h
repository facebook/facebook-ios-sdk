/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@class FBSDKDialogConfiguration;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_DialogConfigurationMapBuilding)
@protocol FBSDKDialogConfigurationMapBuilding

// UNCRUSTIFY_FORMAT_OFF
- (NSDictionary<NSString *, FBSDKDialogConfiguration *> *)buildDialogConfigurationMapWithRawConfigurations:(NSArray<NSDictionary<NSString *, id> *> *)rawConfigurations
NS_SWIFT_NAME(buildDialogConfigurationMap(from:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END
