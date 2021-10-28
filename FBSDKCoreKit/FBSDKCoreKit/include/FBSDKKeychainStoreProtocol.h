/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(KeychainStoreProtocol)
@protocol FBSDKKeychainStore

- (nullable NSString *)stringForKey:(NSString *)key;
- (nullable NSDictionary<NSString *, id> *)dictionaryForKey:(NSString *)key;

- (BOOL)setString:(nullable NSString *)value forKey:(NSString *)key accessibility:(nullable CFTypeRef)accessibility;
- (BOOL)setDictionary:(nullable NSDictionary<NSString *, id> *)value forKey:(NSString *)key accessibility:(nullable CFTypeRef)accessibility;

@end

NS_ASSUME_NONNULL_END
