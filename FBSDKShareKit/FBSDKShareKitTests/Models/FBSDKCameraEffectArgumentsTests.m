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
    FBSDKCameraEffectArguments *unarchivedArguments = [NSKeyedUnarchiver unarchivedObjectOfClass:[FBSDKCameraEffectArguments class] fromData:data error:nil];
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
  [arguments setArray:@[@"a",@"b",@"c"] forKey:@"string_array"];
  XCTAssertEqualObjects([arguments arrayForKey:@"string_array"], (@[@"a",@"b",@"c"]));
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
