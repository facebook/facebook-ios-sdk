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

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@import TestTools;
#import "FBSDKLoginKitTests-Swift.h"

@interface FBSDKAuthenticationTokenHeader (Testing)

- (instancetype)initWithAlg:(NSString *)alg
                        typ:(NSString *)typ
                        kid:(NSString *)kid;

@end

@interface FBSDKAuthenticationTokenHeaderTests : XCTestCase

@property (nonatomic) FBSDKAuthenticationTokenHeader *header;
@property (nonatomic) NSDictionary *headerDict;

@end

@implementation FBSDKAuthenticationTokenHeaderTests

- (void)setUp
{
  [super setUp];

  _header = [[FBSDKAuthenticationTokenHeader alloc] initWithAlg:@"RS256"
                                                            typ:@"JWT"
                                                            kid:@"abcd1234"];

  _headerDict = @{
    @"alg" : _header.alg,
    @"typ" : _header.typ,
    @"kid" : _header.kid,
  };
}

// MARK: - Decoding Header

- (void)testDecodeValidHeader
{
  NSData *headerData = [FBSDKTypeUtility dataWithJSONObject:_headerDict options:0 error:nil];
  NSString *encodedHeader = [self base64URLEncodeData:headerData];

  FBSDKAuthenticationTokenHeader *header = [FBSDKAuthenticationTokenHeader headerFromEncodedString:encodedHeader];
  XCTAssertEqualObjects(header, _header);
}

- (void)testDecodeInvalidFormatHeader
{
  NSData *headerData = [@"invalid_header" dataUsingEncoding:NSUTF8StringEncoding];
  NSString *encodedHeader = [self base64URLEncodeData:headerData];

  XCTAssertNil([FBSDKAuthenticationTokenHeader headerFromEncodedString:encodedHeader]);
}

- (void)testDecodeInvalidHeader
{
  [self assertDecodeHeaderFailWithInvalidEntry:@"alg" value:@"wrong_algorithm"];
  [self assertDecodeHeaderFailWithInvalidEntry:@"alg" value:nil];
  [self assertDecodeHeaderFailWithInvalidEntry:@"alg" value:@""];

  [self assertDecodeHeaderFailWithInvalidEntry:@"typ" value:@"some_type"];
  [self assertDecodeHeaderFailWithInvalidEntry:@"typ" value:nil];
  [self assertDecodeHeaderFailWithInvalidEntry:@"typ" value:@""];

  [self assertDecodeHeaderFailWithInvalidEntry:@"kid" value:nil];
  [self assertDecodeHeaderFailWithInvalidEntry:@"kid" value:@""];
}

- (void)testDecodeEmptyHeader
{
  NSDictionary *header = @{};
  NSData *headerData = [FBSDKTypeUtility dataWithJSONObject:header options:0 error:nil];
  NSString *encodedHeader = [self base64URLEncodeData:headerData];

  XCTAssertNil([FBSDKAuthenticationTokenHeader headerFromEncodedString:encodedHeader]);
}

- (void)testDecodeRandomHeader
{
  for (int i = 0; i < 100; i++) {
    NSDictionary *randomizedHeader = [Fuzzer randomizeWithJson:_headerDict];
    NSData *headerData = [FBSDKTypeUtility dataWithJSONObject:randomizedHeader options:0 error:nil];
    NSString *encodedHeader = [self base64URLEncodeData:headerData];

    [FBSDKAuthenticationTokenHeader headerFromEncodedString:encodedHeader];
  }
}

// MARK: - Helpers

- (void)assertDecodeHeaderFailWithInvalidEntry:(NSString *)key value:(id)value
{
  NSMutableDictionary *invalidHeader = [_headerDict mutableCopy];
  if (value) {
    [FBSDKTypeUtility dictionary:invalidHeader setObject:value forKey:key];
  } else {
    [invalidHeader removeObjectForKey:key];
  }
  NSData *headerData = [FBSDKTypeUtility dataWithJSONObject:invalidHeader options:0 error:nil];
  NSString *encodedHeader = [self base64URLEncodeData:headerData];

  XCTAssertNil([FBSDKAuthenticationTokenHeader headerFromEncodedString:encodedHeader]);
}

- (NSString *)base64URLEncodeData:(NSData *)data
{
  NSString *base64 = [FBSDKBase64 encodeData:data];
  NSString *base64URL = [base64 stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
  base64URL = [base64URL stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
  return [base64URL stringByReplacingOccurrencesOfString:@"=" withString:@""];
}

@end
