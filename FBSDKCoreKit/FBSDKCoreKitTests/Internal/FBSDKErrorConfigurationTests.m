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

#import "FBSDKErrorConfiguration.h"

@interface FBSDKErrorConfigurationTests : XCTestCase

@end

@implementation FBSDKErrorConfigurationTests

- (void)testErrorConfigurationDefaults
{
  FBSDKErrorConfiguration *configuration = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];

  XCTAssertEqual(FBSDKGraphRequestErrorCategoryTransient, [configuration recoveryConfigurationForCode:@"1" subcode:nil request:nil].errorCategory);
  XCTAssertEqual(FBSDKGraphRequestErrorCategoryTransient, [configuration recoveryConfigurationForCode:@"1" subcode:@"12312" request:nil].errorCategory);
  XCTAssertEqual(FBSDKGraphRequestErrorCategoryTransient, [configuration recoveryConfigurationForCode:@"2" subcode:@"*" request:nil].errorCategory);
  XCTAssertNil([configuration recoveryConfigurationForCode:nil subcode:nil request:nil]);
  XCTAssertEqual(FBSDKGraphRequestErrorCategoryRecoverable, [configuration recoveryConfigurationForCode:@"190" subcode:@"459" request:nil].errorCategory);
  XCTAssertEqual(FBSDKGraphRequestErrorCategoryRecoverable, [configuration recoveryConfigurationForCode:@"190" subcode:@"300" request:nil].errorCategory);
  XCTAssertEqualObjects(@"login", [configuration recoveryConfigurationForCode:@"190" subcode:@"458" request:nil].recoveryActionName);
  XCTAssertEqual(FBSDKGraphRequestErrorCategoryRecoverable, [configuration recoveryConfigurationForCode:@"102" subcode:@"*" request:nil].errorCategory);
  XCTAssertNil([configuration recoveryConfigurationForCode:@"104" subcode:nil request:nil]);
}

- (void)testErrorConfigurationAdditonalArray
{
  NSArray *array = @[
                     @{ @"name" : @"other",
                        @"items" : @[ @{ @"code" : @190, @"subcodes": @[ @459 ] } ],
                        },
                     @{ @"name" : @"login",
                        @"items" : @[ @{ @"code" : @1, @"subcodes": @[ @12312 ] } ],
                        @"recovery_message" : @"somemessage",
                        @"recovery_options" : @[ @"Yes", @"No thanks" ]
                        },
                     ];
  FBSDKErrorConfiguration *intermediaryConfiguration = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
  [intermediaryConfiguration parseArray:array];

  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:intermediaryConfiguration];
  FBSDKErrorConfiguration *configuration = [NSKeyedUnarchiver unarchiveObjectWithData:data];

  XCTAssertEqual(FBSDKGraphRequestErrorCategoryTransient, [configuration recoveryConfigurationForCode:@"1" subcode:nil request:nil].errorCategory);
  XCTAssertEqual(FBSDKGraphRequestErrorCategoryRecoverable, [configuration recoveryConfigurationForCode:@"1" subcode:@"12312" request:nil].errorCategory);
  XCTAssertEqual(FBSDKGraphRequestErrorCategoryTransient, [configuration recoveryConfigurationForCode:@"2" subcode:@"*" request:nil].errorCategory);
  XCTAssertNil([configuration recoveryConfigurationForCode:nil subcode:nil request:nil]);
  XCTAssertEqual(FBSDKGraphRequestErrorCategoryOther, [configuration recoveryConfigurationForCode:@"190" subcode:@"459" request:nil].errorCategory);
  XCTAssertEqual(FBSDKGraphRequestErrorCategoryRecoverable, [configuration recoveryConfigurationForCode:@"190" subcode:@"300" request:nil].errorCategory);
  XCTAssertEqual(FBSDKGraphRequestErrorCategoryRecoverable, [configuration recoveryConfigurationForCode:@"102" subcode:@"*" request:nil].errorCategory);
  XCTAssertEqual(FBSDKGraphRequestErrorCategoryOther, [configuration recoveryConfigurationForCode:@"104" subcode:@"800" request:nil].errorCategory);
}

@end
