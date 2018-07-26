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

#import <UIKit/UIKit.h>

#import <XCTest/XCTest.h>

#import "FBSDKCoreKit.h"
#import "FBSDKInternalUtility.h"

@interface FBSDKInternalUtilityTests : XCTestCase
@end

@implementation FBSDKInternalUtilityTests

- (void)testJSONString
{
  NSString *URLString = @"https://www.facebook.com";
  NSURL *URL = [NSURL URLWithString:URLString];
  NSDictionary *dictionary = @{
                               @"url": URL,
                               };
  NSError *error;
  NSString *JSONString = [FBSDKInternalUtility JSONStringForObject:dictionary error:&error invalidObjectHandler:NULL];
  XCTAssertNil(error);
  XCTAssertEqualObjects(JSONString, @"{\"url\":\"https:\\/\\/www.facebook.com\"}");
  NSDictionary *decoded = [FBSDKInternalUtility objectForJSONString:JSONString error:&error];
  XCTAssertNil(error);
  XCTAssertEqualObjects([decoded allKeys], @[@"url"]);
  XCTAssertEqualObjects(decoded[@"url"], URLString);
}

- (void)testURLEncode
{
  NSString *value = @"test this \"string\u2019s\" encoded value";
  NSString *encoded = [FBSDKUtility URLEncode:value];
  XCTAssertEqualObjects(encoded, @"test%20this%20%22string%E2%80%99s%22%20encoded%20value");
  NSString *decoded = [FBSDKUtility URLDecode:encoded];
  XCTAssertEqualObjects(decoded, value);
}

- (void)testURLEncodeSpecialCharacters
{
  NSString *value = @":!*();@/&?#[]+$,='%\"\u2019";
  NSString *encoded = [FBSDKUtility URLEncode:value];
  XCTAssertEqualObjects(encoded, @"%3A%21%2A%28%29%3B%40%2F%26%3F%23%5B%5D%2B%24%2C%3D%27%25%22%E2%80%99");
  NSString *decoded = [FBSDKUtility URLDecode:encoded];
  XCTAssertEqualObjects(decoded, value);
}

- (void)testQueryString
{
  NSURL *URL = [[NSURL alloc] initWithString:@"http://example.com/path/to/page.html?key1&key2=value2&key3=value+3%20%3D%20foo#fragment=go"];
  NSDictionary *dictionary = [FBSDKUtility dictionaryWithQueryString:URL.query];
  NSDictionary *expectedDictionary = @{
                                       @"key1": @"",
                                       @"key2": @"value2",
                                       @"key3": @"value 3 = foo",
                                       };
  XCTAssertEqualObjects(dictionary, expectedDictionary);
  NSString *queryString = [FBSDKUtility queryStringWithDictionary:dictionary error:NULL];
  NSString *expectedQueryString = @"key1=&key2=value2&key3=value%203%20%3D%20foo";
  XCTAssertEqualObjects(queryString, expectedQueryString);

  // test repetition now that the query string has been cleaned and normalized
  NSDictionary *dictionary2 = [FBSDKUtility dictionaryWithQueryString:queryString];
  XCTAssertEqualObjects(dictionary2, expectedDictionary);
  NSString *queryString2 = [FBSDKUtility queryStringWithDictionary:dictionary2 error:NULL];
  XCTAssertEqualObjects(queryString2, expectedQueryString);
}

- (void)testFacebookURL
{
  NSString *URLString;
  NSString *tier = [FBSDKSettings facebookDomainPart];
  [FBSDKSettings setFacebookDomainPart:@""];

  URLString = [FBSDKInternalUtility facebookURLWithHostPrefix:nil path:nil queryParameters:nil error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://facebook.com/" FBSDK_TARGET_PLATFORM_VERSION);

  URLString = [FBSDKInternalUtility facebookURLWithHostPrefix:@"m." path:nil queryParameters:nil error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/" FBSDK_TARGET_PLATFORM_VERSION);

  URLString = [FBSDKInternalUtility facebookURLWithHostPrefix:@"m" path:nil queryParameters:nil error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/" FBSDK_TARGET_PLATFORM_VERSION);

  URLString = [FBSDKInternalUtility facebookURLWithHostPrefix:@"m"
                                                         path:@"/dialog/share"
                                              queryParameters:nil
                                                        error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/" FBSDK_TARGET_PLATFORM_VERSION @"/dialog/share");

  URLString = [FBSDKInternalUtility facebookURLWithHostPrefix:@"m"
                                                         path:@"dialog/share"
                                              queryParameters:nil
                                                        error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/" FBSDK_TARGET_PLATFORM_VERSION @"/dialog/share");

  URLString = [FBSDKInternalUtility facebookURLWithHostPrefix:@"m"
                                                         path:@"dialog/share"
                                              queryParameters:@{ @"key": @"value" }
                                                        error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString,
                        @"https://m.facebook.com/" FBSDK_TARGET_PLATFORM_VERSION @"/dialog/share?key=value");

  URLString = [FBSDKInternalUtility facebookURLWithHostPrefix:@"m"
                                                         path:@"/v1.0/dialog/share"
                                              queryParameters:nil
                                                        error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/v1.0/dialog/share");

  URLString = [FBSDKInternalUtility facebookURLWithHostPrefix:@"m"
                                                         path:@"/dialog/share"
                                              queryParameters:nil
                                               defaultVersion:@"v2.0"
                                                        error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/v2.0/dialog/share");

  URLString = [FBSDKInternalUtility facebookURLWithHostPrefix:@"m"
                                                         path:@"/v1.0/dialog/share"
                                              queryParameters:nil
                                               defaultVersion:@"v2.0"
                                                        error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/v1.0/dialog/share");

  URLString = [FBSDKInternalUtility facebookURLWithHostPrefix:@"m"
                                                         path:@"/v987654321.2/dialog/share"
                                              queryParameters:nil
                                                        error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/v987654321.2/dialog/share");

  URLString = [FBSDKInternalUtility facebookURLWithHostPrefix:@"m"
                                                         path:@"/v.1/dialog/share"
                                              queryParameters:nil
                                               defaultVersion:@"v2.0"
                                                        error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/v2.0/v.1/dialog/share");

  URLString = [FBSDKInternalUtility facebookURLWithHostPrefix:@"m"
                                                         path:@"/v1/dialog/share"
                                              queryParameters:nil
                                               defaultVersion:@"v2.0"
                                                        error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/v2.0/v1/dialog/share");
  [FBSDKSettings setFacebookDomainPart:tier];

  [FBSDKSettings setGraphAPIVersion:@"v3.3"];
  URLString = [FBSDKInternalUtility facebookURLWithHostPrefix:@"m"
                                                         path:@"/v1/dialog/share"
                                              queryParameters:nil
                                               defaultVersion:nil
                                                        error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/v3.3/v1/dialog/share");
  [FBSDKSettings setGraphAPIVersion:nil];
  URLString = [FBSDKInternalUtility facebookURLWithHostPrefix:@"m"
                                                         path:@"/dialog/share"
                                              queryParameters:nil
                                               defaultVersion:nil
                                                        error:NULL].absoluteString;
  XCTAssertEqualObjects(URLString, @"https://m.facebook.com/" FBSDK_TARGET_PLATFORM_VERSION @"/dialog/share");

}

@end
