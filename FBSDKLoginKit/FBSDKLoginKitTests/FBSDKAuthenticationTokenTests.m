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
#import "FBSDKAuthenticationToken.h"

static NSString *const _certificate = @"MIIDgjCCAmoCCQDMso+U6N9AMjANBgkqhkiG9w0BAQsFADCBgjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAldBMRAwDgYDVQQHDAdTZWF0dGxlMREwDwYDVQQKDAhGYWNlYm9vazEMMAoGA1UECwwDRW5nMRIwEAYDVQQDDAlwYW5zeTA0MTkxHzAdBgkqhkiG9w0BCQEWEHBhbnN5MDQxOUBmYi5jb20wHhcNMjAxMTAzMDAzNTI1WhcNMzAxMTAxMDAzNTI1WjCBgjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAldBMRAwDgYDVQQHDAdTZWF0dGxlMREwDwYDVQQKDAhGYWNlYm9vazEMMAoGA1UECwwDRW5nMRIwEAYDVQQDDAlwYW5zeTA0MTkxHzAdBgkqhkiG9w0BCQEWEHBhbnN5MDQxOUBmYi5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD0R8/zzuJ5SM+8KBgshg+sKARfm4Ad7Qv7Vi0L8xoXpReXxefDHF7jI9o6pLsp5OIEmnhRjTlbdT7APK1pZ8dHjOdod6xWSoQigUplYOqa5iuVx7IqD15PUhx6/LqcAtHFKDtKOPuIc8CqkmVUyGRMq2OxdCoiWix5z79pSDILmlRWsn4UOCpFU/Ix75YL/JD19IHgwgh4XCxDwUVhmpgG+jI5l9a3ZCBx7JwZAoJ/Z/OpVbguAlBnxIpi8Qk5VKdHzLHvkrdGXGFMzao6bReXX3KNrYrurAgd7fD2TAQo8EH5rgB7ewxtCIlHRoXJPSdVKpTPwx4c7Mfu2EMpx66pAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAPKMCK6mlLIFxMvIa4lT3fYY+APPhMazHtiPJ+279dkhzGmugD3x+mWvd+OzdmWlW/bvZWLbG3UXA166FK8ZcYyuTYdhCxP3vRNqBWNC65qURnIYyUK2DT09WrvBWLZqhv/mJFfijnGqvkKA1k3rVtgCGNDEnezmC9uuO8P17y3+/RZY8dBfvd8lkdCyTCFnKHNyKAE83qnqAJwgbc7cv7IKwAYsDdr4u38GFayBdTzCatTVrQDTYZbJDJLx+BcvHw8pdhthsX7wpGbFH5++Y5G4hRF2vGenzLFIHthxFnpgiZO3VjloPB57awA4jmJY9DjsOZNhZT+RbnCO9AQlCZE=";

static NSString *const _encodedHeader = @"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9";

static NSString *const _encodedClaims = @"eyJzdWIiOiIxMjM0IiwibmFtZSI6IlRlc3QgVXNlciIsImlzcyI6Imh0dHBzOi8vZmFjZWJvb2suY29tL2RpYWxvZy9vYXV0aCIsImF1ZCI6IjQzMjEiLCJub25jZSI6InNvbWVfbm9uY2UiLCJleHAiOjE1MTYyNTkwMjIsImVtYWlsIjoiZW1haWxAZW1haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vd3d3LmZhY2Vib29rLmNvbS9zb21lX3BpY3R1cmUiLCJpYXQiOjE1MTYyMzkwMjJ9";

static NSString *const _signature = @"rTaqfx5Dz0UbzxZ3vBhitgtetWKBJ3-egz5n6l4ngLYqQ7ywapDvS7cM1NRGAh9drT8QeoxKPm0H_1B1LJBNyx-Fiseetfs7XANuocwTx9k7so3bi_EW0V-RYoDTgg5asS9Ra2qYM829xMYkhBHXp1HwHo0uHz1tafQ1hTsxtzH29t23_EnPpnVx5jvu-UeAEL4Q7VeIIfkweQYzuT3cowWAs-Vhyvl9I39Z4Uh_3ZhkpBJW1CblPW3ekHoySC61qwePM9Fk0q3N7K45LtktIMR5biV0RvJceTGOssHGhjaQ3hzpRq318MZKfBtg6C-Ryhh8SmOkuDrrj-VNdoVHKg";

@interface FBSDKAuthenticationToken (Testing)

- (void)setClaimsWithEncodedString:(NSString *)encodedClaims;

+ (instancetype)emptyInstance;

- (void)setCertificate:(NSString *)certificate;

+ (NSString *)base64FromBase64Url:(NSString *)base64Url;

- (BOOL)verifySignature:(NSString *)signature
                 header:(NSString *)header
                 claims:(NSString *)claims;

- (NSDictionary *)claims;

@end

@interface FBSDKAuthenticationTokenTests : XCTestCase

@end

@implementation FBSDKAuthenticationTokenTests

- (void)testDecodeValidClaims
{
  NSDictionary *expectedClaims = @{
    @"sub" : @"1234",
    @"name" : @"Test User",
    @"iss" : @"https://facebook.com/dialog/oauth",
    @"aud" : @"4321",
    @"nonce" : @"some_nonce",
    @"exp" : @1516259022,
    @"email" : @"email@email.com",
    @"picture" : @"https://www.facebook.com/some_picture",
    @"iat" : @1516239022,
  };
  NSData *expectedClaimsData = [FBSDKTypeUtility dataWithJSONObject:expectedClaims options:0 error:nil];
  NSString *encodedClaims = [self base64URLEncodeData:expectedClaimsData];
  FBSDKAuthenticationToken *token = [FBSDKAuthenticationToken emptyInstance];

  [token setClaimsWithEncodedString:encodedClaims];
  XCTAssertEqualObjects(token.claims, expectedClaims);
}

- (void)testCreateWithInvalidFormatTokenShouldFail
{
  FBSDKAuthenticationToken *token = [[FBSDKAuthenticationToken alloc] initWithTokenString:@"invalid_id_token"];
  XCTAssertNil(token);
}

- (void)testVerifyValidSignatureShouldSucceed
{
  FBSDKAuthenticationToken *token = [FBSDKAuthenticationToken emptyInstance];
  [token setCertificate:_certificate];

  XCTAssertTrue(
    [token verifySignature:_signature
                      header:_encodedHeader
                      claims:_encodedClaims]
  );
}

- (void)testVerifyInvalidSignatureShouldFail
{
  FBSDKAuthenticationToken *token = [FBSDKAuthenticationToken emptyInstance];
  [token setCertificate:_certificate];

  NSString *invalidSignature = @"hH0uCpIx0BhjT_djfI52wPMp0sYuHAHYOes4GVasXykHsZAeuidFYshiCd8O-KpAo5m9jZWbXdaSN0JMbpBIJ9TwSk6e8bhX-N6BRKl3EZRby6SsZtK9J2X6mWomgMCfJZD54McLIdDQaTTtNsV1kgzm8iksywaT3f1GdicqlJPZn3m83xF3toSdfKdPoJJCpM7IidPru7gF8aZchkE1d-dUzZ9mV0CPfsl5lX4M64f470nm6PzyynAvyKwUBKO3v3x08V17NV8OkRAjtGPRhbs_d4B6ifEXS3piWUlxVm6w27nPbdmKeCqjV-WRfIJ6lOvumR2F26I1soEwtEWq9g";

  XCTAssertFalse(
    [token verifySignature:invalidSignature
                      header:_encodedHeader
                      claims:_encodedClaims]
  );
}

- (void)testVerifySignatureWithInvalidCertificateShouldFail
{
  FBSDKAuthenticationToken *token = [FBSDKAuthenticationToken emptyInstance];
  [token setCertificate:@"invalid_certification"];

  XCTAssertFalse(
    [token verifySignature:_signature
                      header:_encodedHeader
                      claims:_encodedClaims]
  );
}

- (void)testBase64FromBase64Url
{
  NSString *expectedString = @"testBase64FromBase64Url";
  NSData *data = [expectedString dataUsingEncoding:NSUTF8StringEncoding];
  NSString *base64UrlEncoded = [self base64URLEncodeData:data];
  NSString *base64Encoded = [FBSDKAuthenticationToken base64FromBase64Url:base64UrlEncoded];
  XCTAssertEqualObjects([FBSDKBase64 decodeAsString:base64Encoded], expectedString);

  // test nil
  XCTAssertNil([FBSDKAuthenticationToken base64FromBase64Url:nil]);

  // test empty string
  XCTAssertEqualObjects([FBSDKAuthenticationToken base64FromBase64Url:@""], @"");
}

- (NSString *)base64URLEncodeData:(NSData *)data
{
  NSString *base64 = [FBSDKBase64 encodeData:data];
  NSString *base64URL = [base64 stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
  base64URL = [base64URL stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
  return [base64URL stringByReplacingOccurrencesOfString:@"=" withString:@""];
}

@end
