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

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "FBSDKJSONValue.h"

@interface FBSDKJSONValueTests : XCTestCase
@end

@implementation FBSDKJSONValueTests

- (void)testReturnsNilForBadInputs
{
  NSError *e;
  XCTAssertNil(FBSDKCreateJSONFromString(nil, &e));
  XCTAssertNil(FBSDKCreateJSONFromString(@"THIS IS NOT JSON", &e));
  XCTAssertNil(FBSDKCreateJSONFromString(@"null", &e));

  // NSData should not be a valid entry in the dictionary to become JSON.
  XCTAssertNil(
    [[FBSDKJSONValue alloc] initWithPotentialJSONObject:@{
       @"id" : [@"BLAH" dataUsingEncoding:NSUTF8StringEncoding]
     }]
  );
}

- (void)testArrayMatcher
{
  NSError *e;
  FBSDKJSONValue *const v = FBSDKCreateJSONFromString(@"[1,2,3,4]", &e);

  __block NSArray *actual = nil;
  [v matchArray:^(NSArray *a) {
       actual = a;
     } dictionary:nil];

  int i = 1;
  for (FBSDKJSONField *field in actual) {
    XCTAssertEqualObjects(field.rawObject, @(i++));
  }
}

- (void)testDictMatcher
{
  NSError *e;
  FBSDKJSONValue *const v = FBSDKCreateJSONFromString(@"{\"id\":5}", &e);

  __block NSDictionary<NSString *, FBSDKJSONField *> *actual = nil;
  [v matchArray:nil dictionary:^(NSDictionary *d) {actual = d; }];

  XCTAssertEqualObjects(actual[@"id"].rawObject, @5);
}

- (void)testDictMatchersThatDontUseBlocks
{
  FBSDKJSONValue *const v = FBSDKCreateJSONFromString(@"{\"id\":5}", nil);
  XCTAssertEqualObjects([v matchDictionaryOrNil][@"id"].rawObject, @5);
  XCTAssertEqualObjects([v unsafe_matchDictionaryOrNil][@"id"], @5);

  XCTAssertNil([v unsafe_matchArrayOrNil]);
  XCTAssertNil([v matchArrayOrNil]);
}

- (void)testArrayMatchersThatDontUseBlocks
{
  FBSDKJSONValue *const v = FBSDKCreateJSONFromString(@"[5]", nil);
  XCTAssertEqualObjects([v matchArrayOrNil][0].rawObject, @5);
  XCTAssertEqualObjects([v unsafe_matchArrayOrNil][0], @5);

  XCTAssertNil([v unsafe_matchDictionaryOrNil]);
  XCTAssertNil([v matchDictionaryOrNil]);
}

#pragma mark - FBSDKJSONField

- (void)testFieldMatchers
{
  NSError *e;
  FBSDKJSONValue *const v = FBSDKCreateJSONFromString(@"[1,\"hi\",null,[1,2,3],{\"key\": \"value\"}]", &e);

  __block NSArray<FBSDKJSONField *> *actual = nil;
  [v matchArray:^(NSArray *a) { actual = a; } dictionary:nil];

  NSArray *const a = @[@1, @2, @3];
  NSDictionary *const d = @{@"key" : @"value"};
  XCTAssertEqualObjects(actual[0].rawObject, @(1));
  XCTAssertEqualObjects([actual[0] numberOrNil], @(1));
  XCTAssertNil([actual[0] stringOrNil]);

  XCTAssertEqualObjects(actual[1].rawObject, @"hi");
  XCTAssertEqualObjects([actual[1] stringOrNil], @"hi");
  XCTAssertNil([actual[1] numberOrNil]);

  XCTAssertEqualObjects(actual[2].rawObject, [NSNull null]);
  XCTAssertEqualObjects([actual[2] nullOrNil], [NSNull null]);
  XCTAssertNil([actual[2] stringOrNil]);

  XCTAssertEqualObjects(actual[3].rawObject, a);
  XCTAssertTrue([actual[3] arrayOrNil].count == 3);
  XCTAssertNil([actual[3] stringOrNil]);

  XCTAssertEqualObjects(actual[4].rawObject, d);
  XCTAssertTrue([actual[4] dictionaryOrNil].count == 1);
  XCTAssertNil([actual[4] stringOrNil]);
}

- (void)testMatchingDictionaryField
{
  NSError *e;
  FBSDKJSONValue *const value = FBSDKCreateJSONFromString(@"{\"oh\":\"hi\"}", &e);

  [value matchArray:^(NSArray<FBSDKJSONField *> *match) {
           XCTFail("Should not match an array when none exists in the json string");
         } dictionary:^(NSDictionary<NSString *, FBSDKJSONField *> *match) {
           XCTAssertEqualObjects(match.allKeys.firstObject, @"oh", "Should return a parsed dictionary with the expected key");
           XCTAssertEqualObjects(match[@"oh"].rawObject, @"hi", "Should return valid JSON fields for parsed dictionary values");
         }];
}

@end
