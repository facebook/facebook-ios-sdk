/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#ifdef BUCK
 #import <FBSDKCoreKit/FBSDKCoreKit.h>
#else
@import FBSDKCoreKit;
#endif

#import "FBSDKCameraEffectArguments.h"
#import "FBSDKShareConstants.h"
#import "FBSDKShareModelTestUtility.h"

@interface FBSDKCameraEffectArgumentsTests : XCTestCase
@end

@implementation FBSDKCameraEffectArgumentsTests

- (void)testCopy
{
  FBSDKCameraEffectArguments *arguments = [FBSDKShareModelTestUtility cameraEffectArguments];
  XCTAssertEqualObjects([arguments copy], arguments);
}

- (void)testCoding
{
  FBSDKCameraEffectArguments *arguments = [FBSDKShareModelTestUtility cameraEffectArguments];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:arguments];
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_11_0
  FBSDKCameraEffectArguments *unarchivedArguments = [NSKeyedUnarchiver unarchivedObjectOfClass:FBSDKCameraEffectArguments.class fromData:data error:nil];
#else
  FBSDKCameraEffectArguments *unarchivedArguments = [NSKeyedUnarchiver unarchiveObjectWithData:data];
#endif
  XCTAssertEqualObjects(unarchivedArguments, arguments);
}

- (void)testTypes
{
  FBSDKCameraEffectArguments *arguments = [FBSDKCameraEffectArguments new];

  // Supported types
  [arguments setString:@"1234" forKey:@"string"];
  XCTAssertEqualObjects([arguments stringForKey:@"string"], @"1234");
  [arguments setArray:@[@"a", @"b", @"c"] forKey:@"string_array"];
  XCTAssertEqualObjects([arguments arrayForKey:@"string_array"], (@[@"a", @"b", @"c"]));
  [arguments setArray:@[] forKey:@"empty_array"];
  XCTAssertEqualObjects([arguments arrayForKey:@"empty_array"], @[]);
  [arguments setString:nil forKey:@"nil_string"];
  XCTAssertEqualObjects([arguments arrayForKey:@"nil_string"], nil);
  [arguments setArray:nil forKey:@"nil_array"];
  XCTAssertEqualObjects([arguments arrayForKey:@"nil_array"], nil);

  // Unsupported types
  XCTAssertThrows([arguments setString:(NSString *)[NSData new] forKey:@"fake_string"]);
}

@end
