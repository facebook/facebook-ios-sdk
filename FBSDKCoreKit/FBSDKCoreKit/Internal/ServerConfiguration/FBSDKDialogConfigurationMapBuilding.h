/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKDialogConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DialogConfigurationMapBuilding)
@protocol FBSDKDialogConfigurationMapBuilding

// UNCRUSTIFY_FORMAT_OFF
- (NSDictionary<NSString *, FBSDKDialogConfiguration *> *)buildDialogConfigurationMapWithRawConfigurations:(NSArray<NSDictionary<NSString *, id> *> *)rawConfigurations
NS_SWIFT_NAME(buildDialogConfigurationMap(from:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END
