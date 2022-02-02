/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// An internal protocol used to describe a simple data store
NS_SWIFT_NAME(DataPersisting)
@protocol FBSDKDataPersisting

- (void)setInteger:(NSInteger)value
            forKey:(NSString *)defaultName;
- (void)setObject:(id)value
           forKey:(NSString *)defaultName;
- (nullable NSData *)dataForKey:(NSString *)defaultName;
- (NSInteger)integerForKey:(NSString *)defaultName;
- (nullable NSString *)stringForKey:(NSString *)defaultName;
- (nullable id)objectForKey:(NSString *)defaultName;
- (void)removeObjectForKey:(NSString *)defaultName;

@end

NS_ASSUME_NONNULL_END
