/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AppEventParametersExtracting)
@protocol FBSDKAppEventParametersExtracting

- (NSMutableDictionary<NSString *, NSString *> *)activityParametersDictionaryForEvent:(NSString *)eventCategory
                                                            shouldAccessAdvertisingID:(BOOL)shouldAccessAdvertisingID
                                                                               userID:(nullable NSString *)userID
                                                                             userData:(nullable NSString *)userData;

@end

NS_ASSUME_NONNULL_END
