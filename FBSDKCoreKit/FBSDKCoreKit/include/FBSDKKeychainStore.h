/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKKeychainStoreProtocol.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(KeychainStore)
@interface FBSDKKeychainStore : NSObject <FBSDKKeychainStore>

@property (nonatomic, readonly, copy) NSString *service;
@property (nonatomic, readonly, copy) NSString *accessGroup;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithService:(NSString *)service accessGroup:(nullable NSString *)accessGroup NS_DESIGNATED_INITIALIZER;

- (BOOL)setData:(nullable NSData *)value forKey:(NSString *)key accessibility:(CFTypeRef)accessibility;
- (nullable NSData *)dataForKey:(NSString *)key;

// hook for subclasses to override keychain query construction.
- (NSMutableDictionary<NSString *, id> *)queryForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
