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

#import "FBSDKCoreKit.h"
#import "FBSDKCoreKitTests-Swift.h"

@interface FBSDKUserAgeRangeTests : XCTestCase
@end

@implementation FBSDKUserAgeRangeTests

// MARK: Creation

- (void)testCreateWithMinOnly
{
  NSDictionary *dict = @{@"min" : @((long)1)};
  FBSDKUserAgeRange *ageRange = [FBSDKUserAgeRange ageRangeFromDictionary:dict];

  XCTAssertNotNil(
    ageRange,
    @"Should be able to create UserAgeRange with min value specified"
  );
  XCTAssertEqualObjects(ageRange.min, dict[@"min"]);
  XCTAssertNil(ageRange.max);
}

- (void)testCreateWithMaxOnly
{
  NSDictionary *dict = @{@"max" : @((long)1)};
  FBSDKUserAgeRange *ageRange = [FBSDKUserAgeRange ageRangeFromDictionary:dict];

  XCTAssertNotNil(
    ageRange,
    @"Should be able to create UserAgeRange with max value specified"
  );
  XCTAssertNil(ageRange.min);
  XCTAssertEqualObjects(ageRange.max, dict[@"max"]);
}

- (void)testCreateWithMinSmallerThanMax
{
  NSDictionary *dict = @{@"min" : @((long)1), @"max" : @((long)2)};
  FBSDKUserAgeRange *ageRange = [FBSDKUserAgeRange ageRangeFromDictionary:dict];

  XCTAssertNotNil(
    ageRange,
    @"Should be able to create UserAgeRange with min value smaller than max"
  );
  XCTAssertEqualObjects(ageRange.min, dict[@"min"]);
  XCTAssertEqualObjects(ageRange.max, dict[@"max"]);
}

- (void)testCreateWithNilDictionary
{
  NSDictionary *dict = nil;
  XCTAssertNil(
    [FBSDKUserAgeRange ageRangeFromDictionary:dict],
    @"Should not be able to create UserAgeRange from nil"
  );
}

- (void)testCreateFromString
{
  NSDictionary *dict = (NSDictionary *)@"test";
  XCTAssertNil(
    [FBSDKUserAgeRange ageRangeFromDictionary:dict],
    @"Should not be able to create UserAgeRange from string"
  );
}

- (void)testCreateFromEmptyDictionary
{
  XCTAssertNil(
    [FBSDKUserAgeRange ageRangeFromDictionary:@{}],
    @"Should not be able to create UserAgeRange from empty dictionary"
  );
}

- (void)testCreateWithNegativeMin
{
  NSDictionary *dict = @{@"min" : @((long)-1)};
  XCTAssertNil(
    [FBSDKUserAgeRange ageRangeFromDictionary:dict],
    @"Should not be able to create UserAgeRange with negative min value"
  );
}

- (void)testCreateWithNegativeMax
{
  NSDictionary *dict = @{@"max" : @((long)-1)};
  XCTAssertNil(
    [FBSDKUserAgeRange ageRangeFromDictionary:dict],
    @"Should not be able to create UserAgeRange with negative max value"
  );
}

- (void)testCreateWithMinLargerThanMax
{
  NSDictionary *dict = @{@"min" : @((long)2), @"max" : @((long)1)};
  XCTAssertNil(
    [FBSDKUserAgeRange ageRangeFromDictionary:dict],
    @"Should not be able to create UserAgeRange with min larger than max"
  );
}

- (void)testCreateWithMinEqualToMax
{
  NSDictionary *dict = @{@"min" : @((long)1), @"max" : @((long)1)};
  FBSDKUserAgeRange *ageRange = [FBSDKUserAgeRange ageRangeFromDictionary:dict];

  XCTAssertNil(
    ageRange,
    @"Should not be able to create UserAgeRange with min value equal to max"
  );
}

- (void)testCreateFromDictionaryWithStringValues
{
  NSDictionary *dict = @{@"min" : @"min", @"max" : @"max"};
  XCTAssertNil(
    [FBSDKUserAgeRange ageRangeFromDictionary:dict],
    @"Should not be able to create UserAgeRange with string values"
  );
}

- (void)testCreateWithRandomData
{
  NSDictionary *dict = @{@"min" : @"min", @"max" : @"max"};

  for (int i = 0; i < 100; i++) {
    NSDictionary *randomizedDict = [Fuzzer randomizeWithJson:dict];
    [FBSDKUserAgeRange ageRangeFromDictionary:randomizedDict];
  }
}

// MARK: Storage
- (void)testEncoding
{
  NSDictionary *dict = @{@"min" : @((long)1), @"max" : @((long)2)};
  FBSDKUserAgeRange *ageRange = [FBSDKUserAgeRange ageRangeFromDictionary:dict];
  FBSDKTestCoder *coder = FBSDKTestCoder.new;

  [ageRange encodeWithCoder:coder];

  XCTAssertEqualObjects(
    coder.encodedObject[@"FBSDKUserAgeRangeMinCodingKey"],
    ageRange.min,
    @"Should encode the expected min value"
  );

  XCTAssertEqualObjects(
    coder.encodedObject[@"FBSDKUserAgeRangeMaxCodingKey"],
    ageRange.max,
    @"Should encode the expected max value"
  );
}

- (void)testDecoding
{
  FBSDKTestCoder *coder = FBSDKTestCoder.new;

  FBSDKUserAgeRange *ageRange = [[FBSDKUserAgeRange alloc] initWithCoder:coder];

  XCTAssertNotNil(ageRange);
  XCTAssertEqualObjects(
    coder.decodedObject[@"FBSDKUserAgeRangeMinCodingKey"],
    NSNumber.class,
    "Should decode a number for the min key"
  );

  XCTAssertEqualObjects(
    coder.decodedObject[@"FBSDKUserAgeRangeMaxCodingKey"],
    NSNumber.class,
    "Should decode a number for the max key"
  );
}

@end
