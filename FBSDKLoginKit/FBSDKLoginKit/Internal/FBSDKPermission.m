/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKPermission.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@implementation FBSDKPermission

- (nullable instancetype)initWithString:(NSString *)string
{
  NSString *permission = [FBSDKTypeUtility coercedToStringValue:string];
  if (permission.length <= 0) {
    return nil;
  }

  NSCharacterSet *allowedSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz_"];
  if (![[string stringByTrimmingCharactersInSet:allowedSet] isEqualToString:@""]) {
    return nil;
  }

  if ((self = [super init])) {
    _value = permission;
  }
  return self;
}

+ (nullable NSSet<FBSDKPermission *> *)permissionsFromRawPermissions:(NSSet<NSString *> *)rawPermissions
{
  NSMutableSet<FBSDKPermission *> *permissions = [NSMutableSet new];

  for (NSString *rawPermission in rawPermissions) {
    FBSDKPermission *permission = [[FBSDKPermission alloc] initWithString:rawPermission];
    if (!permission) {
      return nil;
    }
    [permissions addObject:permission];
  }

  return permissions;
}

+ (NSSet<NSString *> *)rawPermissionsFromPermissions:(NSSet<FBSDKPermission *> *)permissions
{
  NSMutableSet<NSString *> *rawPermissions = [NSMutableSet new];

  for (FBSDKPermission *permission in permissions) {
    [rawPermissions addObject:permission.value];
  }

  return rawPermissions;
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:FBSDKPermission.class]) {
    return NO;
  }

  FBSDKPermission *other = (FBSDKPermission *)object;
  return [self.value isEqualToString:other.value];
}

- (NSString *)description
{
  return self.value;
}

- (NSUInteger)hash
{
  return self.value.hash;
}

@end
