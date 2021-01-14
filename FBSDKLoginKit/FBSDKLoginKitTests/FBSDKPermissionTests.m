// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
  NSSet *permissions = [NSSet setWithArray:@[
    [[FBSDKPermission alloc] initWithString:@"email"],
    [[FBSDKPermission alloc] initWithString:@"public_profile"],
                        ]];

  NSArray *rawPermissions = [FBSDKPermission rawPermissionsFromPermissions:permissions].allObjects;
  NSArray *expectedRawPermissions = @[@"email", @"public_profile"];
  XCTAssertEqualObjects(rawPermissions, expectedRawPermissions);
}

- (void)testPermissionsFromValidRawPermissions
{
  NSSet *rawPermissions = [NSSet setWithArray:@[@"email", @"user_friends"]];

  NSArray *permissions = [FBSDKPermission permissionsFromRawPermissions:rawPermissions].allObjects;
  NSArray *expectedPermissions = @[
    [[FBSDKPermission alloc] initWithString:@"email"],
    [[FBSDKPermission alloc] initWithString:@"user_friends"],
  ];
  XCTAssertEqualObjects(permissions, expectedPermissions);
}

- (void)testPermissionsFromInvalidRawPermissions
{
  NSSet *rawPermissions = [NSSet setWithArray:@[@"email", @""]];

  NSArray *permissions = [FBSDKPermission permissionsFromRawPermissions:rawPermissions].allObjects;
  XCTAssertNil(permissions);
}

@end
