/*
 * Copyright (c) Facebook, Inc. and its affiliates.
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
    FBSDK_CAST_TO_CLASS_OR_NIL(a, ClassB),
    "Casting from a known class to a non-matching class should fail and return nil"
  );

  id idA = a;
  XCTAssertNil(
    FBSDK_CAST_TO_CLASS_OR_NIL(idA, ClassB),
    "Casting from an unknown class to a non-matching class should fail and return nil"
  );
}

- (void)testCastingToMatchingClass
{
  ClassA *a = [ClassA new];
  XCTAssertEqual(
    FBSDK_CAST_TO_CLASS_OR_NIL(a, ClassA),
    a,
    "Casting from a known class to a matching class should return the same instance of that class"
  );

  id idA = a;
  XCTAssertEqual(
    FBSDK_CAST_TO_CLASS_OR_NIL(idA, ClassA),
    idA,
    "Casting from an unknown class to a matching class should return the same instance of that class"
  );
}

- (void)testCastingToNonConformingProtocol
{
  id<ProtocolA> a = [ClassA new];
  XCTAssertNil(
    FBSDK_CAST_TO_PROTOCOL_OR_NIL(a, ProtocolB),
    "Should not return an object if it does not conform to the stated protocol"
  );

  id idA = a;
  XCTAssertNil(
    FBSDK_CAST_TO_PROTOCOL_OR_NIL(idA, ProtocolB),
    "Should not return an object if it does not conform to the stated protocol"
  );
}

- (void)testCastingToConformingMatchingProtocol
{
  ClassA *a = [ClassA new];
  XCTAssertNil(
    FBSDK_CAST_TO_PROTOCOL_OR_NIL(a, ProtocolB),
    "Should return an object if it conforms to the stated protocol"
  );

  id idA = a;
  XCTAssertNil(
    FBSDK_CAST_TO_PROTOCOL_OR_NIL(idA, ProtocolB),
    "Should return an object if it conforms to the stated protocol"
  );
}

- (void)testCastingNil
{
  id foo = @"bar";
  foo = nil;

  XCTAssertNil(FBSDK_CAST_TO_CLASS_OR_NIL(foo, NSString));
}

@end
