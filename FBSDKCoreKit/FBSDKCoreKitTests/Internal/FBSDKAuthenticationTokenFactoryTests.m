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

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKTestCase.h"

static NSString *const _certificate = @"MIIDgjCCAmoCCQDMso+U6N9AMjANBgkqhkiG9w0BAQsFADCBgjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAldBMRAwDgYDVQQHDAdTZWF0dGxlMREwDwYDVQQKDAhGYWNlYm9vazEMMAoGA1UECwwDRW5nMRIwEAYDVQQDDAlwYW5zeTA0MTkxHzAdBgkqhkiG9w0BCQEWEHBhbnN5MDQxOUBmYi5jb20wHhcNMjAxMTAzMDAzNTI1WhcNMzAxMTAxMDAzNTI1WjCBgjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAldBMRAwDgYDVQQHDAdTZWF0dGxlMREwDwYDVQQKDAhGYWNlYm9vazEMMAoGA1UECwwDRW5nMRIwEAYDVQQDDAlwYW5zeTA0MTkxHzAdBgkqhkiG9w0BCQEWEHBhbnN5MDQxOUBmYi5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD0R8/zzuJ5SM+8KBgshg+sKARfm4Ad7Qv7Vi0L8xoXpReXxefDHF7jI9o6pLsp5OIEmnhRjTlbdT7APK1pZ8dHjOdod6xWSoQigUplYOqa5iuVx7IqD15PUhx6/LqcAtHFKDtKOPuIc8CqkmVUyGRMq2OxdCoiWix5z79pSDILmlRWsn4UOCpFU/Ix75YL/JD19IHgwgh4XCxDwUVhmpgG+jI5l9a3ZCBx7JwZAoJ/Z/OpVbguAlBnxIpi8Qk5VKdHzLHvkrdGXGFMzao6bReXX3KNrYrurAgd7fD2TAQo8EH5rgB7ewxtCIlHRoXJPSdVKpTPwx4c7Mfu2EMpx66pAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAPKMCK6mlLIFxMvIa4lT3fYY+APPhMazHtiPJ+279dkhzGmugD3x+mWvd+OzdmWlW/bvZWLbG3UXA166FK8ZcYyuTYdhCxP3vRNqBWNC65qURnIYyUK2DT09WrvBWLZqhv/mJFfijnGqvkKA1k3rVtgCGNDEnezmC9uuO8P17y3+/RZY8dBfvd8lkdCyTCFnKHNyKAE83qnqAJwgbc7cv7IKwAYsDdr4u38GFayBdTzCatTVrQDTYZbJDJLx+BcvHw8pdhthsX7wpGbFH5++Y5G4hRF2vGenzLFIHthxFnpgiZO3VjloPB57awA4jmJY9DjsOZNhZT+RbnCO9AQlCZE=";

static NSString *const _encodedHeader = @"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9";

static NSString *const _encodedClaims = @"eyJzdWIiOiIxMjM0IiwibmFtZSI6IlRlc3QgVXNlciIsImlzcyI6Imh0dHBzOi8vZmFjZWJvb2suY29tL2RpYWxvZy9vYXV0aCIsImF1ZCI6IjQzMjEiLCJub25jZSI6InNvbWVfbm9uY2UiLCJleHAiOjE1MTYyNTkwMjIsImVtYWlsIjoiZW1haWxAZW1haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vd3d3LmZhY2Vib29rLmNvbS9zb21lX3BpY3R1cmUiLCJpYXQiOjE1MTYyMzkwMjJ9";

static NSString *const _signature = @"rTaqfx5Dz0UbzxZ3vBhitgtetWKBJ3-egz5n6l4ngLYqQ7ywapDvS7cM1NRGAh9drT8QeoxKPm0H_1B1LJBNyx-Fiseetfs7XANuocwTx9k7so3bi_EW0V-RYoDTgg5asS9Ra2qYM829xMYkhBHXp1HwHo0uHz1tafQ1hTsxtzH29t23_EnPpnVx5jvu-UeAEL4Q7VeIIfkweQYzuT3cowWAs-Vhyvl9I39Z4Uh_3ZhkpBJW1CblPW3ekHoySC61qwePM9Fk0q3N7K45LtktIMR5biV0RvJceTGOssHGhjaQ3hzpRq318MZKfBtg6C-Ryhh8SmOkuDrrj-VNdoVHKg";

static NSString *const _mockAppID = @"4321";

static NSString *const _mockNonce = @"some_nonce";

static NSString *const _facebookURL = @"https://facebook.com/dialog/oauth";

@interface FBSDKAuthenticationTokenFactory (Testing)

+ (NSDictionary *)validatedClaimsWithEncodedString:(NSString *)encodedClaims nonce:(NSString *)nonce;
+ (NSDictionary *)validatedHeaderWithEncodedString:(NSString *)encodedHeader;

- (void)setCertificate:(NSString *)certificate;

+ (NSString *)base64FromBase64Url:(NSString *)base64Url;

- (BOOL)verifySignature:(NSString *)signature
                 header:(NSString *)header
                 claims:(NSString *)claims;

- (NSDictionary *)claims;

@end

@interface FBSDKAuthenticationTokenFactoryTests : FBSDKTestCase

@end

@implementation FBSDKAuthenticationTokenFactoryTests
{
  NSDictionary *_claims;
  NSDictionary *_header;
}

- (void)setUp
{
  [super setUp];

  [self stubAppID:_mockAppID];

  long currentTime = [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] longValue];
  _claims = @{
    @"iss" : _facebookURL,
    @"aud" : _mockAppID,
    @"nonce" : _mockNonce,
    @"exp" : @(currentTime + 60 * 60 * 48), // 2 days later
    @"iat" : @(currentTime - 60), // 1 min ago
    @"sub" : @"1234",
    @"name" : @"Test User",
    @"email" : @"email@email.com",
    @"picture" : @"https://www.facebook.com/some_picture",
  };

  _header = @{
    @"alg" : @"RS256",
    @"typ" : @"JWT"
  };
}

// MARK: - Creation

- (void)testCreateWithInvalidFormatTokenShouldFail
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  FBSDKAuthenticationTokenBlock completion = ^(FBSDKAuthenticationToken *token) {
    XCTAssertNil(token);
    [expectation fulfill];
  };

  [[FBSDKAuthenticationTokenFactory new] createTokenFromTokenString:@"invalid_token" nonce:@"123456789" completion:completion];

  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    XCTAssertNil(error);
  }];
}

// MARK: - Decoding Claims

- (void)testDecodeValidClaimsShouldSucceed
{
  NSData *claimsData = [FBSDKTypeUtility dataWithJSONObject:_claims options:0 error:nil];
  NSString *encodedClaims = [self base64URLEncodeData:claimsData];

  NSDictionary *claims = [FBSDKAuthenticationTokenFactory validatedClaimsWithEncodedString:encodedClaims nonce:_mockNonce];
  XCTAssertEqualObjects(claims, _claims);
}

- (void)testDecodeInvalidFormatClaimsShouldFail
{
  NSData *claimsData = [@"invalid_claims" dataUsingEncoding:NSUTF8StringEncoding];
  NSString *encodedClaims = [self base64URLEncodeData:claimsData];

  XCTAssertNil([FBSDKAuthenticationTokenFactory validatedClaimsWithEncodedString:encodedClaims nonce:_mockNonce]);
}

- (void)testDecodeInvalidClaimsShouldFail
{
  long currentTime = [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] longValue];

  // non facebook issuer
  [self assertDecodeClaimsFailWithInvalidEntry:@"iss"
                                         value:@"https://notfacebook.com"];

  // incorrect audience
  [self assertDecodeClaimsFailWithInvalidEntry:@"aud"
                                         value:@"wrong_app_id"];

  // expired
  [self assertDecodeClaimsFailWithInvalidEntry:@"exp"
                                         value:@(currentTime - 60 * 60)];

  // issued too long ago
  [self assertDecodeClaimsFailWithInvalidEntry:@"iat"
                                         value:@(currentTime - 60 * 60)];

  // incorrect nonce
  [self assertDecodeClaimsFailWithInvalidEntry:@"nonce"
                                         value:@"incorrect_nonce"];

  // invalid user ID
  [self assertDecodeClaimsFailWithInvalidEntry:@"sub"
                                         value:nil];
  [self assertDecodeClaimsFailWithInvalidEntry:@"sub"
                                         value:@1234];
  [self assertDecodeClaimsFailWithInvalidEntry:@"sub"
                                         value:@""];
}

- (void)testDecodeEmptyClaims
{
  NSDictionary *claims = @{};
  NSData *claimsData = [FBSDKTypeUtility dataWithJSONObject:claims options:0 error:nil];
  NSString *encodedClaims = [self base64URLEncodeData:claimsData];

  XCTAssertNil([FBSDKAuthenticationTokenFactory validatedClaimsWithEncodedString:encodedClaims nonce:_mockNonce]);
}

- (void)testDecodeRandomClaims
{
  for (int i = 0; i < 100; i++) {
    NSDictionary *randomizedClaims = [self randomizeDictionary:_claims];
    NSData *claimsData = [FBSDKTypeUtility dataWithJSONObject:randomizedClaims options:0 error:nil];
    NSString *encodedClaims = [self base64URLEncodeData:claimsData];

    [FBSDKAuthenticationTokenFactory validatedClaimsWithEncodedString:encodedClaims nonce:_mockNonce];
  }
}

// MARK: - Decoding Header

- (void)testDecodeValidHeaderShouldSucceed
{
  NSData *headerData = [FBSDKTypeUtility dataWithJSONObject:_header options:0 error:nil];
  NSString *encodedHeader = [self base64URLEncodeData:headerData];

  NSDictionary *header = [FBSDKAuthenticationTokenFactory validatedHeaderWithEncodedString:encodedHeader];
  XCTAssertEqualObjects(header, _header);
}

- (void)testDecodeInvalidFormatHeaderShouldFail
{
  NSData *headerData = [@"invalid_header" dataUsingEncoding:NSUTF8StringEncoding];
  NSString *encodedHeader = [self base64URLEncodeData:headerData];

  XCTAssertNil([FBSDKAuthenticationTokenFactory validatedHeaderWithEncodedString:encodedHeader]);
}

- (void)testDecodeInvalidHeaderShouldFail
{
  NSMutableDictionary *invalidHeader = [_header mutableCopy];
  [FBSDKTypeUtility dictionary:invalidHeader setObject:@"wrong algorithm" forKey:@"alg"];
  NSData *invalidHeaderData = [FBSDKTypeUtility dataWithJSONObject:invalidHeader options:0 error:nil];
  NSString *encodedHeader = [self base64URLEncodeData:invalidHeaderData];

  XCTAssertNil([FBSDKAuthenticationTokenFactory validatedHeaderWithEncodedString:encodedHeader]);
}

- (void)testDecodeEmptyHeader
{
  NSDictionary *header = @{};
  NSData *headerData = [FBSDKTypeUtility dataWithJSONObject:header options:0 error:nil];
  NSString *encodedHeader = [self base64URLEncodeData:headerData];

  XCTAssertNil([FBSDKAuthenticationTokenFactory validatedHeaderWithEncodedString:encodedHeader]);
}

// MARK: - Verifying Signature

- (void)testVerifyValidSignatureShouldSucceed
{
  FBSDKAuthenticationTokenFactory *factory = [FBSDKAuthenticationTokenFactory new];
  [factory setCertificate:_certificate];

  XCTAssertTrue(
    [factory verifySignature:_signature
                      header:_encodedHeader
                      claims:_encodedClaims]
  );
}

- (void)testVerifyInvalidSignatureShouldFail
{
  FBSDKAuthenticationTokenFactory *factory = [FBSDKAuthenticationTokenFactory new];
  [factory setCertificate:_certificate];

  NSString *invalidSignature = @"hH0uCpIx0BhjT_djfI52wPMp0sYuHAHYOes4GVasXykHsZAeuidFYshiCd8O-KpAo5m9jZWbXdaSN0JMbpBIJ9TwSk6e8bhX-N6BRKl3EZRby6SsZtK9J2X6mWomgMCfJZD54McLIdDQaTTtNsV1kgzm8iksywaT3f1GdicqlJPZn3m83xF3toSdfKdPoJJCpM7IidPru7gF8aZchkE1d-dUzZ9mV0CPfsl5lX4M64f470nm6PzyynAvyKwUBKO3v3x08V17NV8OkRAjtGPRhbs_d4B6ifEXS3piWUlxVm6w27nPbdmKeCqjV-WRfIJ6lOvumR2F26I1soEwtEWq9g";

  XCTAssertFalse(
    [factory verifySignature:invalidSignature
                      header:_encodedHeader
                      claims:_encodedClaims]
  );
}

- (void)testVerifySignatureWithInvalidCertificateShouldFail
{
  FBSDKAuthenticationTokenFactory *factory = [FBSDKAuthenticationTokenFactory new];
  [factory setCertificate:@"invalid_certification"];

  XCTAssertFalse(
    [factory verifySignature:_signature
                      header:_encodedHeader
                      claims:_encodedClaims]
  );
}

// MARK: - Utilities

- (void)testBase64FromBase64Url
{
  NSString *expectedString = @"testBase64FromBase64Url";
  NSData *data = [expectedString dataUsingEncoding:NSUTF8StringEncoding];
  NSString *base64UrlEncoded = [self base64URLEncodeData:data];
  NSString *base64Encoded = [FBSDKAuthenticationTokenFactory base64FromBase64Url:base64UrlEncoded];
  XCTAssertEqualObjects([FBSDKBase64 decodeAsString:base64Encoded], expectedString);

  // test nil
  XCTAssertNil([FBSDKAuthenticationTokenFactory base64FromBase64Url:nil]);

  // test empty string
  XCTAssertEqualObjects([FBSDKAuthenticationTokenFactory base64FromBase64Url:@""], @"");
}

- (void)assertDecodeClaimsFailWithInvalidEntry:(NSString *)key value:(id)value
{
  NSMutableDictionary *invalidClaims = [_claims mutableCopy];
  if (value) {
    [FBSDKTypeUtility dictionary:invalidClaims setObject:value forKey:key];
  } else {
    [invalidClaims removeObjectForKey:key];
  }

  NSData *claimsData = [FBSDKTypeUtility dataWithJSONObject:invalidClaims options:0 error:nil];
  NSString *encodedClaims = [self base64URLEncodeData:claimsData];

  XCTAssertNil([FBSDKAuthenticationTokenFactory validatedClaimsWithEncodedString:encodedClaims nonce:_mockNonce]);
}

- (NSString *)base64URLEncodeData:(NSData *)data
{
  NSString *base64 = [FBSDKBase64 encodeData:data];
  NSString *base64URL = [base64 stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
  base64URL = [base64URL stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
  return [base64URL stringByReplacingOccurrencesOfString:@"=" withString:@""];
}

- (NSDictionary *)randomizeDictionary:(NSDictionary *)dictionary
{
  NSArray *values = @[@YES, @NO, @1, @0, @-1, @INT32_MAX, @LONG_MAX, @MAXFLOAT, @"1", @"a", @"[ { \"something\": nonexistent } ]"];
  NSMutableDictionary *randomized = [dictionary mutableCopy];
  for (NSString *key in dictionary) {
    int randOption = arc4random() % 3;
    switch (randOption) {
      case 0:
        [randomized removeObjectForKey:key];
        break;
      case 1:
        [FBSDKTypeUtility dictionary:randomized setObject:[FBSDKTypeUtility array:values objectAtIndex:arc4random() % values.count] forKey:key];
        break;
      case 2:
      default:
        break;
    }
  }

  return randomized;
}

@end
