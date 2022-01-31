/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

#import "FBSDKSafeCast.h"

@interface ClassA : NSObject
@end

@implementation ClassA
@end

@interface ClassB : NSObject
@end

@implementation ClassB
@end

@interface FBSDKSafeCastTests : XCTestCase
@end

@implementation FBSDKSafeCastTests

- (void)testCastingToNonMatchingClass
{
  ClassA *a = [ClassA new];
  XCTAssertNil(
    _FBSDKCastToClassOrNilUnsafeInternal(a, ClassB.class),
    "Casting from a known class to a non-matching class should fail and return nil"
  );

  id idA = a;
  XCTAssertNil(
    _FBSDKCastToClassOrNilUnsafeInternal(idA, ClassB.class),
    "Casting from an unknown class to a non-matching class should fail and return nil"
  );
}

- (void)testCastingToMatchingClass
{
  ClassA *a = [ClassA new];
  XCTAssertEqual(
    _FBSDKCastToClassOrNilUnsafeInternal(a, ClassA.class),
    a,
    "Casting from a known class to a matching class should return the same instance of that class"
  );

  id idA = a;
  XCTAssertEqual(
    _FBSDKCastToClassOrNilUnsafeInternal(idA, ClassA.class),
    idA,
    "Casting from an unknown class to a matching class should return the same instance of that class"
  );
}

- (void)testCastingNil
{
  id foo = @"bar";
  foo = nil;

  XCTAssertNil(_FBSDKCastToClassOrNilUnsafeInternal(foo, NSString.class));
}

@end
