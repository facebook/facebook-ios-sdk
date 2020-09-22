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

#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKErrorConfiguration.h"

@interface FBSDKErrorConfigurationTests : XCTestCase

@end

@implementation FBSDKErrorConfigurationTests
{
  NSArray *rawErrorCodeConfiguration;
}

- (void)setUp
{
  [super setUp];

  rawErrorCodeConfiguration = @[
    @{ @"name" : @"other",
       @"items" : @[@{ @"code" : @190, @"subcodes" : @[@459] }], },
    @{ @"name" : @"login",
       @"items" : @[@{ @"code" : @1, @"subcodes" : @[@12312] }],
       @"recovery_message" : @"somemessage",
       @"recovery_options" : @[@"Yes", @"No thanks"]},
  ];
}

- (void)testErrorConfigurationDefaults
{
  FBSDKErrorConfiguration *configuration = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];

  XCTAssertEqual(FBSDKGraphRequestErrorTransient, [configuration recoveryConfigurationForCode:@"1" subcode:nil request:nil].errorCategory);
  XCTAssertEqual(FBSDKGraphRequestErrorTransient, [configuration recoveryConfigurationForCode:@"1" subcode:@"12312" request:nil].errorCategory);
  XCTAssertEqual(FBSDKGraphRequestErrorTransient, [configuration recoveryConfigurationForCode:@"2" subcode:@"*" request:nil].errorCategory);
  XCTAssertNil([configuration recoveryConfigurationForCode:nil subcode:nil request:nil]);
  XCTAssertEqual(FBSDKGraphRequestErrorRecoverable, [configuration recoveryConfigurationForCode:@"190" subcode:@"459" request:nil].errorCategory);
  XCTAssertEqual(FBSDKGraphRequestErrorRecoverable, [configuration recoveryConfigurationForCode:@"190" subcode:@"300" request:nil].errorCategory);
  XCTAssertEqualObjects(@"login", [configuration recoveryConfigurationForCode:@"190" subcode:@"458" request:nil].recoveryActionName);
  XCTAssertEqual(FBSDKGraphRequestErrorRecoverable, [configuration recoveryConfigurationForCode:@"102" subcode:@"*" request:nil].errorCategory);
  XCTAssertNil([configuration recoveryConfigurationForCode:@"104" subcode:nil request:nil]);
}

- (void)testErrorConfigurationAdditonalArray
{
  FBSDKErrorConfiguration *intermediaryConfiguration = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
  [intermediaryConfiguration parseArray:rawErrorCodeConfiguration];

  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:intermediaryConfiguration];
  FBSDKErrorConfiguration *configuration = [NSKeyedUnarchiver unarchiveObjectWithData:data];

  XCTAssertEqual(FBSDKGraphRequestErrorTransient, [configuration recoveryConfigurationForCode:@"1" subcode:nil request:nil].errorCategory);
  XCTAssertEqual(FBSDKGraphRequestErrorRecoverable, [configuration recoveryConfigurationForCode:@"1" subcode:@"12312" request:nil].errorCategory);
  XCTAssertEqual(FBSDKGraphRequestErrorTransient, [configuration recoveryConfigurationForCode:@"2" subcode:@"*" request:nil].errorCategory);
  XCTAssertNil([configuration recoveryConfigurationForCode:nil subcode:nil request:nil]);
  XCTAssertEqual(FBSDKGraphRequestErrorOther, [configuration recoveryConfigurationForCode:@"190" subcode:@"459" request:nil].errorCategory);
  XCTAssertEqual(FBSDKGraphRequestErrorRecoverable, [configuration recoveryConfigurationForCode:@"190" subcode:@"300" request:nil].errorCategory);
  XCTAssertEqual(FBSDKGraphRequestErrorRecoverable, [configuration recoveryConfigurationForCode:@"102" subcode:@"*" request:nil].errorCategory);
  XCTAssertEqual(FBSDKGraphRequestErrorOther, [configuration recoveryConfigurationForCode:@"104" subcode:@"800" request:nil].errorCategory);
}

- (void)testParsingRandomName
{
  for (int i = 0; i < 1000; i++) {
    NSArray *array = @[
      @{ @"name" : Fuzzer.random,
         @"items" : @[@{ @"code" : @190, @"subcodes" : @[@459] }], },
      @{ @"name" : @"login",
         @"items" : @[@{ @"code" : @1, @"subcodes" : @[@12312] }],
         @"recovery_message" : @"somemessage",
         @"recovery_options" : @[@"Yes", @"No thanks"]},
    ];

    FBSDKErrorConfiguration *configuration = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
    [configuration parseArray:array];
  }
}

- (void)testParsingRandomSubcodes
{
  for (int i = 0; i < 1000; i++) {
    NSArray *array = @[
      @{ @"name" : @"other",
         @"items" : @[@{ @"code" : @190, @"subcodes" : @[Fuzzer.random] }], },
      @{ @"name" : @"login",
         @"items" : @[@{ @"code" : @1, @"subcodes" : @[Fuzzer.random] }],
         @"recovery_message" : @"somemessage",
         @"recovery_options" : @[@"Yes", @"No thanks"]},
    ];

    FBSDKErrorConfiguration *configuration = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
    [configuration parseArray:array];
  }
}

- (void)testParsingRandomCodes
{
  for (int i = 0; i < 1000; i++) {
    NSArray *array = @[
      @{ @"name" : @"other",
         @"items" : @[@{ @"code" : Fuzzer.random, @"subcodes" : @[@459] }], },
      @{ @"name" : @"login",
         @"items" : @[@{ @"code" : Fuzzer.random, @"subcodes" : @[@12312] }],
         @"recovery_message" : @"somemessage",
         @"recovery_options" : @[@"Yes", @"No thanks"]},
    ];

    FBSDKErrorConfiguration *configuration = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
    [configuration parseArray:array];
  }
}

- (void)testParsingRandomItemDictionaries
{
  for (int i = 0; i < 1000; i++) {
    NSArray *array = @[
      @{ @"name" : @"other",
         @"items" : @[Fuzzer.random], },
      @{ @"name" : @"login",
         @"items" : @[Fuzzer.random],
         @"recovery_message" : @"somemessage",
         @"recovery_options" : @[@"Yes", @"No thanks"]},
    ];

    FBSDKErrorConfiguration *configuration = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
    [configuration parseArray:array];
  }
}

- (void)testParsingRandomItems
{
  for (int i = 0; i < 1000; i++) {
    NSArray *array = @[
      @{ @"name" : @"other",
         @"items" : Fuzzer.random, },
      @{ @"name" : @"login",
         @"items" : Fuzzer.random,
         @"recovery_message" : @"somemessage",
         @"recovery_options" : @[@"Yes", @"No thanks"]},
    ];

    FBSDKErrorConfiguration *configuration = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
    [configuration parseArray:array];
  }
}

- (void)testParsingRandomRecoveryMessage
{
  for (int i = 0; i < 1000; i++) {
    NSArray *array = @[
      @{ @"name" : @"other",
         @"items" : @[@{ @"code" : @190, @"subcodes" : @[@459] }], },
      @{ @"name" : @"login",
         @"items" : @[@{ @"code" : @1, @"subcodes" : @[@12312] }],
         @"recovery_message" : Fuzzer.random,
         @"recovery_options" : @[@"Yes", @"No thanks"]},
    ];

    FBSDKErrorConfiguration *configuration = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
    [configuration parseArray:array];
  }
}

- (void)testParsingRandomRecoveryOptionsArray
{
  for (int i = 0; i < 1000; i++) {
    NSArray *array = @[
      @{ @"name" : @"other",
         @"items" : @[@{ @"code" : @190, @"subcodes" : @[@459] }], },
      @{ @"name" : @"login",
         @"items" : @[@{ @"code" : @1, @"subcodes" : @[@12312] }],
         @"recovery_message" : @"somemessage",
         @"recovery_options" : @[Fuzzer.random, Fuzzer.random]},
    ];

    FBSDKErrorConfiguration *configuration = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
    [configuration parseArray:array];
  }
}

- (void)testParsingRandomRecoveryOptions
{
  for (int i = 0; i < 1000; i++) {
    NSArray *array = @[
      @{ @"name" : @"other",
         @"items" : @[@{ @"code" : @190, @"subcodes" : @[@459] }], },
      @{ @"name" : @"login",
         @"items" : @[@{ @"code" : @1, @"subcodes" : @[@12312] }],
         @"recovery_message" : @"somemessage",
         @"recovery_options" : Fuzzer.random},
    ];

    FBSDKErrorConfiguration *configuration = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
    [configuration parseArray:array];
  }
}

- (void)testParsingRecoveryMessageWithoutOptions
{
  for (int i = 0; i < 1000; i++) {
    NSArray *array = @[
      @{ @"name" : @"other",
         @"items" : @[@{ @"code" : @190, @"subcodes" : @[@459] }], },
      @{ @"name" : @"login",
         @"items" : @[@{ @"code" : @1, @"subcodes" : @[@12312] }],
         @"recovery_message" : @"somemessage", },
    ];

    FBSDKErrorConfiguration *configuration = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
    [configuration parseArray:array];
  }
}

- (void)testParsingRecoveryOptionsWithoutMessage
{
  for (int i = 0; i < 1000; i++) {
    NSArray *array = @[
      @{ @"name" : @"other",
         @"items" : @[@{ @"code" : @190, @"subcodes" : @[@459] }], },
      @{ @"name" : @"login",
         @"items" : @[@{ @"code" : @1, @"subcodes" : @[@12312] }],
         @"recovery_options" : @[@"Yes", @"No thanks"]},
    ];

    FBSDKErrorConfiguration *configuration = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
    [configuration parseArray:array];
  }
}

- (void)testParsingRandomEntries
{
  for (int i = 0; i < 1000; i++) {
    NSArray *array = [Fuzzer randomizeWithJson:rawErrorCodeConfiguration];

    FBSDKErrorConfiguration *configuration = [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
    [configuration parseArray:array];
  }
}

@end
