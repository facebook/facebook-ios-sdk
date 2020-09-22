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

#import "FBSDKInternalUtility.h"

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
