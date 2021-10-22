/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(FBPermission)
@interface FBSDKPermission : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 The raw string representation of the permission
*/
@property (nonatomic, readonly, copy) NSString *value;

/**
 Attempts to initialize a new permission with the given string.
 Creation will fail and return nil if the string is invalid.

 @param string the raw permission string
*/
- (nullable instancetype)initWithString:(NSString *)string;

/**
 Returns a set of FBSDKPermission from a set of raw permissions strings.
 Will return nil if any of the input permissions is invalid.
*/
+ (nullable NSSet<FBSDKPermission *> *)permissionsFromRawPermissions:(NSSet<NSString *> *)rawPermissions;

/**
 Returns a set of string permissions from a set of FBSDKPermission by
 extracting the "value" property for each element.
*/
+ (NSSet<NSString *> *)rawPermissionsFromPermissions:(NSSet<FBSDKPermission *> *)permissions;

@end

NS_ASSUME_NONNULL_END
