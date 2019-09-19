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

#import "FBSDKBasicUtility.h"
#import "FBSDKCoreKit.h"

@interface FBSDKBasicUtilityTests : XCTestCase
@end

@implementation FBSDKBasicUtilityTests

- (void)testJSONString
{
  NSString *URLString = @"https://www.facebook.com";
  NSURL *URL = [NSURL URLWithString:URLString];
  NSDictionary<NSString *, id> *dictionary = @{
                                               @"url": URL,
                                               };
  NSError *error;
  NSString *JSONString = [FBSDKBasicUtility JSONStringForObject:dictionary error:&error invalidObjectHandler:NULL];
  XCTAssertNil(error);
  XCTAssertEqualObjects(JSONString, @"{\"url\":\"https:\\/\\/www.facebook.com\"}");
  NSDictionary<id, id> *decoded = [FBSDKBasicUtility objectForJSONString:JSONString error:&error];
  XCTAssertNil(error);
  XCTAssertEqualObjects([decoded allKeys], @[@"url"]);
  XCTAssertEqualObjects(decoded[@"url"], URLString);
}

- (void)testConvertRequestValue
{
  NSNumber *value1 = @1;
  id result1 = [FBSDKBasicUtility convertRequestValue:value1];
  XCTAssertTrue([result1 isKindOfClass:[NSString class]]);
  XCTAssertEqualObjects(result1, @"1");

  NSURL *value2= [NSURL URLWithString:@"https://test"];
  id result2 = [FBSDKBasicUtility convertRequestValue:value2];
  XCTAssertTrue([result2 isKindOfClass:[NSString class]]);
  XCTAssertEqualObjects(result2, @"https://test");

  NSMutableArray<id> *value3 = [NSMutableArray array];
  id result3 = [FBSDKBasicUtility convertRequestValue:value3];
  XCTAssertTrue([result3 isKindOfClass:[NSMutableArray class]]);
}

- (void)testQueryString
{
  NSURL *URL = [NSURL URLWithString:@"http://example.com/path/to/page.html?key1&key2=value2&key3=value+3%20%3D%20foo#fragment=go"];
  NSDictionary<NSString *, NSString *> *dictionary = [FBSDKBasicUtility dictionaryWithQueryString:URL.query];
  NSDictionary<NSString *, NSString *> *expectedDictionary = @{
                                                               @"key1": @"",
                                                               @"key2": @"value2",
                                                               @"key3": @"value 3 = foo",
                                                               };
  XCTAssertEqualObjects(dictionary, expectedDictionary);
  NSString *queryString = [FBSDKBasicUtility queryStringWithDictionary:dictionary error:NULL invalidObjectHandler:NULL];
  NSString *expectedQueryString = @"key1=&key2=value2&key3=value%203%20%3D%20foo";
  XCTAssertEqualObjects(queryString, expectedQueryString);

  // test repetition now that the query string has been cleaned and normalized
  NSDictionary<NSString *, NSString *> *dictionary2 = [FBSDKBasicUtility dictionaryWithQueryString:queryString];
  XCTAssertEqualObjects(dictionary2, expectedDictionary);
  NSString *queryString2 = [FBSDKBasicUtility queryStringWithDictionary:dictionary2 error:NULL invalidObjectHandler:NULL];
  XCTAssertEqualObjects(queryString2, expectedQueryString);
}

- (void)testURLEncode
{
  NSString *value = @"test this \"string\u2019s\" encoded value";
  NSString *encoded = [FBSDKBasicUtility URLEncode:value];
  XCTAssertEqualObjects(encoded, @"test%20this%20%22string%E2%80%99s%22%20encoded%20value");
  NSString *decoded = [FBSDKBasicUtility URLDecode:encoded];
  XCTAssertEqualObjects(decoded, value);
}

- (void)testURLEncodeSpecialCharacters
{
  NSString *value = @":!*();@/&?#[]+$,='%\"\u2019";
  NSString *encoded = [FBSDKBasicUtility URLEncode:value];
  XCTAssertEqualObjects(encoded, @"%3A%21%2A%28%29%3B%40%2F%26%3F%23%5B%5D%2B%24%2C%3D%27%25%22%E2%80%99");
  NSString *decoded = [FBSDKBasicUtility URLDecode:encoded];
  XCTAssertEqualObjects(decoded, value);
}

@end
