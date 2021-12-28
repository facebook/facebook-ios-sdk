/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@protocol ProtocolA <NSObject>
@end

@protocol ProtocolB <NSObject>
@end

@interface ClassA : NSObject <ProtocolA>
@end

@implementation ClassA
@end

@interface ClassB : NSObject <ProtocolB>
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

- (void)testCastingToNonConformingProtocol
{
  id<ProtocolA> a = [ClassA new];
  XCTAssertNil(
    _FBSDKCastToProtocolOrNilUnsafeInternal(a, @protocol(ProtocolB)),
    "Should not return an object if it does not conform to the stated protocol"
  );

  id idA = a;
  XCTAssertNil(
    _FBSDKCastToProtocolOrNilUnsafeInternal(idA, @protocol(ProtocolB)),
    "Should not return an object if it does not conform to the stated protocol"
  );
}

- (void)testCastingToConformingMatchingProtocol
{
  ClassA *a = [ClassA new];
  XCTAssertNil(
    _FBSDKCastToProtocolOrNilUnsafeInternal(a, @protocol(ProtocolB)),
    "Should return an object if it conforms to the stated protocol"
  );

  id idA = a;
  XCTAssertNil(
    _FBSDKCastToProtocolOrNilUnsafeInternal(idA, @protocol(ProtocolB)),
    "Should return an object if it conforms to the stated protocol"
  );
}

- (void)testCastingNil
{
  id foo = @"bar";
  foo = nil;

  XCTAssertNil(_FBSDKCastToClassOrNilUnsafeInternal(foo, NSString.class));
}

@end
