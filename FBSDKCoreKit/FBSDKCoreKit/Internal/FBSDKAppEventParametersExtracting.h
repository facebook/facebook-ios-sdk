/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// An internal protocol used to describe anything that can extract parameters for an app event
NS_SWIFT_NAME(AppEventParametersExtracting)
@protocol FBSDKAppEventParametersExtracting

- (NSMutableDictionary<NSString *, NSString *> *)activityParametersDictionaryForEvent:(NSString *)eventCategory
                                                            shouldAccessAdvertisingID:(BOOL)shouldAccessAdvertisingID
                                                                               userID:(nullable NSString *)userID
                                                                             userData:(nullable NSString *)userData;

@end

NS_ASSUME_NONNULL_END
