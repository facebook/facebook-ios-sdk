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

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKCoreKitTests-Swift.h"

@interface FBSDKTypeUtilityTests : XCTestCase

@end

@implementation FBSDKTypeUtilityTests
{
  NSArray *validJSONObjects;
  NSArray *invalidJSONObjects;
}

- (void)setUp
{
  [super setUp];

  validJSONObjects = @[
    @{ @"foo" : @"bar" },
    @[@1, @2, @3],
    @[],
    @{},
  ];

  invalidJSONObjects = @[
    @"SomeString",
    @{ @1 : @"one" },
    @"",
  ];
}

- (void)testIsValidJSONWithValidJSON
{
  for (id object in validJSONObjects) {
    XCTAssertTrue([FBSDKTypeUtility isValidJSONObject:object], @"%@ is not a valid json object", object);
  }
}

- (void)testIsValidJSONWithInvalidJSON
{
  for (id object in invalidJSONObjects) {
    XCTAssertFalse([FBSDKTypeUtility isValidJSONObject:object], @"%@ is a valid json object", object);
  }
}

- (void)testIsValidJSONWithRandomValues
{
  // Should not crash for any given value
  for (int i = 0; i < 1000; i++) {
    [FBSDKTypeUtility isValidJSONObject:Fuzzer.random];
  }
}

- (void)testDataWithJSONObjectWithValidJSON
{
  for (id object in validJSONObjects) {
    XCTAssertNotNil(
      [FBSDKTypeUtility dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil],
      "Valid json object %@ should produce data",
      object
    );
  }
}

- (void)testDataWithJSONObjectWithInvalidJSON
{
  for (id object in invalidJSONObjects) {
    XCTAssertNil(
      [FBSDKTypeUtility dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil],
      "Valid json object %@ should produce data",
      object
    );
  }
}

- (void)testJSONObjectWithDataWithValidData
{
  for (id object in validJSONObjects) {
    NSData *data = [FBSDKTypeUtility dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];

    XCTAssertEqualObjects(
      [FBSDKTypeUtility JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil],
      object,
      "Should be able to create objects from valid serialized JSON data"
    );
  }
}

- (void)testJSONObjectWithDataWithInvalidData
{
  NSArray *invalidData = @[
    [@"SomeString" dataUsingEncoding:NSUTF8StringEncoding],
    [[@{ @1 : @"one" } description] dataUsingEncoding:NSUTF8StringEncoding],
    [@"" dataUsingEncoding:NSUTF8StringEncoding],
    [NSData data],
    [NSDate date],
  ];

  for (NSData *data in invalidData) {
    XCTAssertNil(
      [FBSDKTypeUtility JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil],
      "Should not be able to create a JSON objrct from invalid data"
    );
  }
}

- (void)testArrayAccessEmptyArray
{
  NSArray *array = @[];

  XCTAssertNil(
    [FBSDKTypeUtility array:array objectAtIndex:5],
    "Should return nil and not crash when accessing invalid indices"
  );
}

- (void)testArrayAccessNonEmptyArrayInvalidIndex
{
  NSArray *array = @[@1, @2, @3];

  XCTAssertNil(
    [FBSDKTypeUtility array:array objectAtIndex:5],
    "Should return nil and not crash when accessing invalid indices"
  );
}

- (void)testArrayAccessNonEmptyArrayZeroIndex
{
  NSArray *array = @[@1, @2, @3];

  XCTAssertEqualObjects(
    [array objectAtIndex:0],
    @1,
    "Should be able to retrive a valid object at the first index of an array"
  );
}

- (void)testArrayAccessNonEmptyArrayValidIndex
{
  NSArray *array = @[@1, @2, @3];

  XCTAssertEqualObjects(
    [array objectAtIndex:2],
    @3,
    "Should be able to retrive a valid object at a valid index of an array"
  );
}

- (void)testAddingArrayObjectAtIndexEmptyArray
{
  NSMutableArray *array = [NSMutableArray array];
  [FBSDKTypeUtility array:array addObject:@"foo" atIndex:0];

  XCTAssertEqualObjects(
    [array objectAtIndex:0],
    @"foo",
    "Should be able to insert a valid object into an empty array"
  );
}

- (void)testAddingArrayObjectAtIndexNonEmptyArray
{
  NSMutableArray *array = [NSMutableArray array];
  [FBSDKTypeUtility array:array addObject:@"foo" atIndex:0];
  [FBSDKTypeUtility array:array addObject:@"bar" atIndex:1];

  XCTAssertEqualObjects(
    [array objectAtIndex:1],
    @"bar",
    "Should be able to insert a valid object into an available position in a non empty array"
  );
}

- (void)testAddingArrayObjectAtDuplicateIndex
{
  NSMutableArray *array = [NSMutableArray array];
  [FBSDKTypeUtility array:array addObject:@"foo" atIndex:0];
  [FBSDKTypeUtility array:array addObject:@"bar" atIndex:0];

  XCTAssertEqualObjects(
    [array objectAtIndex:0],
    @"bar",
    "Should be able to insert a valid object at a non-empty index"
  );
}

- (void)testAddingArrayObjectAtUnavailableIndex
{
  NSMutableArray *array = [NSMutableArray array];
  [FBSDKTypeUtility array:array addObject:@"foo" atIndex:5];

  XCTAssertNil([FBSDKTypeUtility array:array objectAtIndex:0], "Should not be able to insert a valid object at an invalid index");
}

@end
