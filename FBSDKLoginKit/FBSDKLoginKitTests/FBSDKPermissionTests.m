/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

#ifdef BUCK
 #import <FBSDKLoginKit+Internal/FBSDKPermission.h>
#else
 #import "FBSDKPermission.h"
#endif

@interface FBSDKPermissionTests : XCTestCase

@end

@implementation FBSDKPermissionTests

- (void)testInvalidPermissions
{
  NSArray *permissions = @[
    @"",
    @"foo bar",
    @"PUBLIC_PROFILE",
    @"public profile",
    @"public-profile",
    @"123_abc"
  ];

  for (NSString *rawPermission in permissions) {
    FBSDKPermission *permission = [[FBSDKPermission alloc] initWithString:rawPermission];
    XCTAssertNil(permission);
  }
}

- (void)testValidPermissions
{
  NSArray *permissions = @[
    @"email",
    @"public_profile",
    @"pages_manage_ads"
  ];

  for (NSString *rawPermission in permissions) {
    FBSDKPermission *permission = [[FBSDKPermission alloc] initWithString:rawPermission];
    XCTAssertEqualObjects(permission.value, rawPermission);
  }
}

- (void)testRawPermissionsFromPermissions
{
  NSSet<FBSDKPermission *> *permissions = [NSSet setWithArray:@[
    [[FBSDKPermission alloc] initWithString:@"email"],
    [[FBSDKPermission alloc] initWithString:@"public_profile"],
                                           ]];

  NSArray *rawPermissions = [FBSDKPermission rawPermissionsFromPermissions:permissions].allObjects;
  NSArray *expectedRawPermissions = @[@"email", @"public_profile"];
  XCTAssertEqualObjects(rawPermissions, expectedRawPermissions);
}

- (void)testPermissionsFromValidRawPermissions
{
  NSSet<NSString *> *rawPermissions = [NSSet setWithArray:@[@"email", @"user_friends"]];

  NSArray *permissions = [FBSDKPermission permissionsFromRawPermissions:rawPermissions].allObjects;
  NSArray *expectedPermissions = @[
    [[FBSDKPermission alloc] initWithString:@"email"],
    [[FBSDKPermission alloc] initWithString:@"user_friends"],
  ];
  XCTAssertEqualObjects(permissions, expectedPermissions);
}

- (void)testPermissionsFromInvalidRawPermissions
{
  NSSet<NSString *> *rawPermissions = [NSSet setWithArray:@[@"email", @""]];

  NSArray *permissions = [FBSDKPermission permissionsFromRawPermissions:rawPermissions].allObjects;
  XCTAssertNil(permissions);
}

- (void)testDescription
{
  FBSDKPermission *permission = [[FBSDKPermission alloc] initWithString:@"test_permission"];
  XCTAssertEqualObjects(permission.description, permission.value, @"A permission's description should be equal to its value");
}

- (void)testEquality
{
  FBSDKPermission *permission1 = [[FBSDKPermission alloc] initWithString:@"test_permission"];
  XCTAssertTrue([permission1 isEqual:permission1], @"A permission should be equal to itself");

  FBSDKPermission *permission2 = [[FBSDKPermission alloc] initWithString:@"test_permission"];
  XCTAssertTrue([permission1 isEqual:permission2], @"Permissions with equal string values should be equal");
}

- (void)testInequality
{
  FBSDKPermission *permission1 = [[FBSDKPermission alloc] initWithString:@"test_permission"];
  XCTAssertFalse([permission1 isEqual:@"test_permission"], @"Permissions are not equal to objects of other types");

  FBSDKPermission *permission2 = [[FBSDKPermission alloc] initWithString:@"different_permission"];
  XCTAssertFalse([permission1 isEqual:permission2], @"Permissions with unequal string values should be unequal");
}

@end
