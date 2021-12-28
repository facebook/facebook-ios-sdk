/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@import TestTools;

#import "FBSDKCoreKit_BasicsTests-Swift.h"

@interface FBSDKTypeUtilityTests : XCTestCase

@property (nonatomic) NSArray *validJSONObjects;
@property (nonatomic) NSArray *invalidJSONObjects;

@end

@implementation FBSDKTypeUtilityTests

- (void)setUp
{
  [super setUp];

  self.validJSONObjects = @[
    @{ @"foo" : @"bar" },
    @[@1, @2, @3],
    @[],
    @{},
  ];

  self.invalidJSONObjects = @[
    @"SomeString",
    @{ @1 : @"one" },
    @"",
  ];
}

- (void)testIsValidJSONWithValidJSON
{
  for (id object in self.validJSONObjects) {
    XCTAssertTrue([FBSDKTypeUtility isValidJSONObject:object], @"%@ is not a valid json object", object);
  }
}

- (void)testIsValidJSONWithInvalidJSON
{
  for (id object in self.invalidJSONObjects) {
    XCTAssertFalse([FBSDKTypeUtility isValidJSONObject:object], @"%@ is a valid json object", object);
  }
}

- (void)testIsValidJSONWithRandomValues
{
  // Should not crash for any given value
  for (int i = 0; i < 100; i++) {
    [FBSDKTypeUtility isValidJSONObject:Fuzzer.random];
  }
}

- (void)testDataWithJSONObjectWithValidJSON
{
  for (id object in self.validJSONObjects) {
    XCTAssertNotNil(
      [FBSDKTypeUtility dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil],
      "Valid json object %@ should produce data",
      object
    );
  }
}

- (void)testDataWithJSONObjectWithInvalidJSON
{
  for (id object in self.invalidJSONObjects) {
    XCTAssertNil(
      [FBSDKTypeUtility dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil],
      "Valid json object %@ should produce data",
      object
    );
  }
}

- (void)testJSONObjectWithDataWithValidData
{
  for (id object in self.validJSONObjects) {
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
  NSArray<NSNumber *> *array = @[@1, @2, @3];

  XCTAssertNil(
    [FBSDKTypeUtility array:array objectAtIndex:5],
    "Should return nil and not crash when accessing invalid indices"
  );
}

- (void)testArrayAccessNonEmptyArrayZeroIndex
{
  NSArray<NSNumber *> *array = @[@1, @2, @3];

  XCTAssertEqualObjects(
    [array objectAtIndex:0],
    @1,
    "Should be able to retrive a valid object at the first index of an array"
  );
}

- (void)testArrayAccessNonEmptyArrayValidIndex
{
  NSArray<NSNumber *> *array = @[@1, @2, @3];

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
