/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

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
@property (nonatomic) NSDictionary<NSString *, id> *headerDict;

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
  NSDictionary<NSString *, id> *header = @{};
  NSData *headerData = [FBSDKTypeUtility dataWithJSONObject:header options:0 error:nil];
  NSString *encodedHeader = [self base64URLEncodeData:headerData];

  XCTAssertNil([FBSDKAuthenticationTokenHeader headerFromEncodedString:encodedHeader]);
}

- (void)testDecodeRandomHeader
{
  for (int i = 0; i < 100; i++) {
    NSDictionary<NSString *, id> *randomizedHeader = [Fuzzer randomizeWithJson:_headerDict];
    NSData *headerData = [FBSDKTypeUtility dataWithJSONObject:randomizedHeader options:0 error:nil];
    NSString *encodedHeader = [self base64URLEncodeData:headerData];

    [FBSDKAuthenticationTokenHeader headerFromEncodedString:encodedHeader];
  }
}

// MARK: - Helpers

- (void)assertDecodeHeaderFailWithInvalidEntry:(NSString *)key value:(id)value
{
  NSMutableDictionary<NSString *, id> *invalidHeader = [_headerDict mutableCopy];
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
