/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(InfoDictionaryProviding)
@protocol FBSDKInfoDictionaryProviding

@property (nullable, readonly, copy) NSDictionary<NSString *, id> *infoDictionary;

- (nullable id)objectForInfoDictionaryKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
