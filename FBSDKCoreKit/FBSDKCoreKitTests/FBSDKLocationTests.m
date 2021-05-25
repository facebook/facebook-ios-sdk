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

@interface FBSDKLocationTests : XCTestCase
@end

@implementation FBSDKLocationTests

// MARK: Creation

- (void)testCreate
{
  NSDictionary *dict = @{@"id" : @"110843418940484", @"name" : @"Seattle, Washington"};
  FBSDKLocation *location = [FBSDKLocation locationFromDictionary:dict];

  XCTAssertNotNil(
    location,
    @"Should be able to create Location"
  );
  XCTAssertEqualObjects(location.id, dict[@"id"]);
  XCTAssertEqualObjects(location.name, dict[@"name"]);
}

- (void)testCreateWithIdOnly
{
  NSDictionary *dict = @{@"id" : @"110843418940484"};
  FBSDKLocation *location = [FBSDKLocation locationFromDictionary:dict];

  XCTAssertNil(
    location,
    @"Should not be able to create Location with no name specified"
  );
}

- (void)testCreateWithNameOnly
{
  NSDictionary *dict = @{@"name" : @"Seattle, Washington"};
  FBSDKLocation *location = [FBSDKLocation locationFromDictionary:dict];

  XCTAssertNil(
    location,
    @"Should not be able to create Location with no id specified"
  );
}

- (void)testCreateWithNilDictionary
{
  NSDictionary *dict = nil;
  XCTAssertNil(
    [FBSDKLocation locationFromDictionary:dict],
    @"Should not be able to create Location from nil"
  );
}

- (void)testCreateFromString
{
  NSDictionary *dict = (NSDictionary *)@"test";
  XCTAssertNil(
    [FBSDKLocation locationFromDictionary:dict],
    @"Should not be able to create Location from string"
  );
}

- (void)testCreateFromEmptyDictionary
{
  XCTAssertNil(
    [FBSDKLocation locationFromDictionary:@{}],
    @"Should not be able to create Location from empty dictionary"
  );
}

- (void)testCreateFromDictionaryWithIntValues
{
  NSDictionary *dict = @{@"id" : @1, @"name" : @1};
  XCTAssertNil(
    [FBSDKLocation locationFromDictionary:dict],
    @"Should not be able to create Location with non-string values"
  );
}

// MARK: Storage
- (void)testEncoding
{
  NSDictionary *dict = @{@"id" : @"110843418940484", @"name" : @"Seattle, Washington"};
  FBSDKLocation *location = [FBSDKLocation locationFromDictionary:dict];
  FBSDKTestCoder *coder = FBSDKTestCoder.new;

  [location encodeWithCoder:coder];

  XCTAssertEqualObjects(
    coder.encodedObject[@"FBSDKLocationIdCodingKey"],
    location.id,
    @"Should encode the expected id value"
  );

  XCTAssertEqualObjects(
    coder.encodedObject[@"FBSDKLocationNameCodingKey"],
    location.name,
    @"Should encode the expected name value"
  );
}

- (void)testDecoding
{
  FBSDKTestCoder *coder = FBSDKTestCoder.new;

  FBSDKLocation *location = [[FBSDKLocation alloc] initWithCoder:coder];

  XCTAssertNotNil(location);
  XCTAssertEqualObjects(
    coder.decodedObject[@"FBSDKLocationIdCodingKey"],
    NSString.class,
    "Should decode a string for the id key"
  );

  XCTAssertEqualObjects(
    coder.decodedObject[@"FBSDKLocationNameCodingKey"],
    NSString.class,
    "Should decode a string for the name key"
  );
}

@end
