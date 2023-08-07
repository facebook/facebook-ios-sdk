/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit_Basics/FBSDKLinking.h>

NS_ASSUME_NONNULL_BEGIN

/// An internal protocol used to describe a simple data store
NS_SWIFT_NAME(DataPersisting)
@protocol FBSDKDataPersisting

- (void)fb_setInteger:(NSInteger)integer
               forKey:(NSString *)key;
- (void)fb_setObject:(id)object
              forKey:(NSString *)key;
- (nullable NSData *)fb_dataForKey:(NSString *)key;
- (NSInteger)fb_integerForKey:(NSString *)key;
- (nullable NSString *)fb_stringForKey:(NSString *)key;
- (nullable id)fb_objectForKey:(NSString *)key;
- (BOOL)fb_boolForKey:(NSString *)key;
- (void)fb_setBool:(BOOL)value forKey:(NSString *)key;
- (void)fb_removeObjectForKey:(NSString *)key;

@end

FB_LINK_CATEGORY_INTERFACE(NSUserDefaults, DataPersisting)
@interface NSUserDefaults (DataPersisting) <FBSDKDataPersisting>

@end

NS_ASSUME_NONNULL_END
