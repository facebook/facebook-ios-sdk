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
#import "FBSDKSessionProviding.h"
#import "FBSDKTestCase.h"

static NSString *const _certificate = @"MIIDgjCCAmoCCQDMso+U6N9AMjANBgkqhkiG9w0BAQsFADCBgjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAldBMRAwDgYDVQQHDAdTZWF0dGxlMREwDwYDVQQKDAhGYWNlYm9vazEMMAoGA1UECwwDRW5nMRIwEAYDVQQDDAlwYW5zeTA0MTkxHzAdBgkqhkiG9w0BCQEWEHBhbnN5MDQxOUBmYi5jb20wHhcNMjAxMTAzMDAzNTI1WhcNMzAxMTAxMDAzNTI1WjCBgjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAldBMRAwDgYDVQQHDAdTZWF0dGxlMREwDwYDVQQKDAhGYWNlYm9vazEMMAoGA1UECwwDRW5nMRIwEAYDVQQDDAlwYW5zeTA0MTkxHzAdBgkqhkiG9w0BCQEWEHBhbnN5MDQxOUBmYi5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD0R8/zzuJ5SM+8KBgshg+sKARfm4Ad7Qv7Vi0L8xoXpReXxefDHF7jI9o6pLsp5OIEmnhRjTlbdT7APK1pZ8dHjOdod6xWSoQigUplYOqa5iuVx7IqD15PUhx6/LqcAtHFKDtKOPuIc8CqkmVUyGRMq2OxdCoiWix5z79pSDILmlRWsn4UOCpFU/Ix75YL/JD19IHgwgh4XCxDwUVhmpgG+jI5l9a3ZCBx7JwZAoJ/Z/OpVbguAlBnxIpi8Qk5VKdHzLHvkrdGXGFMzao6bReXX3KNrYrurAgd7fD2TAQo8EH5rgB7ewxtCIlHRoXJPSdVKpTPwx4c7Mfu2EMpx66pAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAPKMCK6mlLIFxMvIa4lT3fYY+APPhMazHtiPJ+279dkhzGmugD3x+mWvd+OzdmWlW/bvZWLbG3UXA166FK8ZcYyuTYdhCxP3vRNqBWNC65qURnIYyUK2DT09WrvBWLZqhv/mJFfijnGqvkKA1k3rVtgCGNDEnezmC9uuO8P17y3+/RZY8dBfvd8lkdCyTCFnKHNyKAE83qnqAJwgbc7cv7IKwAYsDdr4u38GFayBdTzCatTVrQDTYZbJDJLx+BcvHw8pdhthsX7wpGbFH5++Y5G4hRF2vGenzLFIHthxFnpgiZO3VjloPB57awA4jmJY9DjsOZNhZT+RbnCO9AQlCZE=";
static NSString *const _encodedHeader = @"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9";
static NSString *const _encodedClaims = @"eyJzdWIiOiIxMjM0IiwibmFtZSI6IlRlc3QgVXNlciIsImlzcyI6Imh0dHBzOi8vZmFjZWJvb2suY29tL2RpYWxvZy9vYXV0aCIsImF1ZCI6IjQzMjEiLCJub25jZSI6InNvbWVfbm9uY2UiLCJleHAiOjE1MTYyNTkwMjIsImVtYWlsIjoiZW1haWxAZW1haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vd3d3LmZhY2Vib29rLmNvbS9zb21lX3BpY3R1cmUiLCJpYXQiOjE1MTYyMzkwMjJ9";
static NSString *const _signature = @"rTaqfx5Dz0UbzxZ3vBhitgtetWKBJ3-egz5n6l4ngLYqQ7ywapDvS7cM1NRGAh9drT8QeoxKPm0H_1B1LJBNyx-Fiseetfs7XANuocwTx9k7so3bi_EW0V-RYoDTgg5asS9Ra2qYM829xMYkhBHXp1HwHo0uHz1tafQ1hTsxtzH29t23_EnPpnVx5jvu-UeAEL4Q7VeIIfkweQYzuT3cowWAs-Vhyvl9I39Z4Uh_3ZhkpBJW1CblPW3ekHoySC61qwePM9Fk0q3N7K45LtktIMR5biV0RvJceTGOssHGhjaQ3hzpRq318MZKfBtg6C-Ryhh8SmOkuDrrj-VNdoVHKg";
static NSString *const _certificateKey = @"some_key";
static NSString *const _mockAppID = @"4321";
static NSString *const _mockJTI = @"some_jti";
static NSString *const _mockNonce = @"some_nonce";
static NSString *const _facebookURL = @"https://facebook.com/dialog/oauth";

typedef void (^FBSDKVerifySignatureCompletionBlock)(BOOL success);

@interface FBSDKAuthenticationTokenFactory (Testing)

- (instancetype)initWithSessionProvider:(id<FBSDKSessionProviding>)sessionProvider;
- (void)setCertificate:(NSString *)certificate;
- (BOOL)verifySignature:(NSString *)signature
                 header:(NSString *)header
                 claims:(NSString *)claims
         certificateKey:(NSString *)key
             completion:(FBSDKVerifySignatureCompletionBlock)completion;
- (NSDictionary *)claims;
@end

@interface FBSDKAuthenticationTokenClaims (Testing)

- (instancetype)initWithJti:(NSString *)jti
                        iss:(NSString *)iss
                        aud:(NSString *)aud
                      nonce:(NSString *)nonce
                        exp:(long)exp
                        iat:(long)iat
                        sub:(NSString *)sub
                       name:(nullable NSString *)name
                      email:(nullable NSString *)email
                    picture:(nullable NSString *)picture;

@end

@interface FBSDKAuthenticationTokenHeader (Testing)

- (instancetype)initWithAlg:(NSString *)alg
                        typ:(NSString *)typ
                        kid:(NSString *)kid;

@end

@interface FBSDKAuthenticationTokenFactoryTests : FBSDKTestCase

@end

@implementation FBSDKAuthenticationTokenFactoryTests
{
  FBSDKAuthenticationTokenClaims *_claims;
  NSDictionary *_claimsDict;
  FBSDKAuthenticationTokenHeader *_header;
  NSDictionary *_headerDict;
}

- (void)setUp
{
  [super setUp];

  [self stubAppID:_mockAppID];

  long currentTime = [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] longValue];

  _claims = [[FBSDKAuthenticationTokenClaims alloc] initWithJti:_mockJTI
                                                            iss:_facebookURL
                                                            aud:_mockAppID
                                                          nonce:_mockNonce
                                                            exp:currentTime + 60 * 60 * 48 // 2 days later
                                                            iat:currentTime - 60 // 1 min ago
                                                            sub:@"1234"
                                                           name:@"Test User"
                                                          email:@"email@email.com"
                                                        picture:@"https://www.facebook.com/some_picture"];

  _claimsDict = @{
    @"iss" : _facebookURL,
    @"aud" : _mockAppID,
    @"nonce" : _mockNonce,
    @"exp" : @(currentTime + 60 * 60 * 48), // 2 days later
    @"iat" : @(currentTime - 60), // 1 min ago
    @"jti" : _mockJTI,
    @"sub" : @"1234",
    @"name" : @"Test User",
    @"email" : @"email@email.com",
    @"picture" : @"https://www.facebook.com/some_picture",
  };

  _header = [[FBSDKAuthenticationTokenHeader alloc] initWithAlg:@"RS256"
                                                            typ:@"JWT"
                                                            kid:@"abcd1234"];

  _headerDict = @{
    @"alg" : @"RS256",
    @"typ" : @"JWT",
    @"kid" : @"abcd1234",
  };
}

// MARK: - Creation

- (void)testCreateWithInvalidFormatToken
{
  __block BOOL wasCalled = NO;
  FBSDKAuthenticationTokenBlock completion = ^(FBSDKAuthenticationToken *token) {
    XCTAssertNil(token);
    wasCalled = YES;
  };

  [[FBSDKAuthenticationTokenFactory new] createTokenFromTokenString:@"invalid_token" nonce:@"123456789" completion:completion];

  XCTAssertTrue(wasCalled, @"Completion handler should be called syncronously");
}

// MARK: - Decoding Claims

- (void)testDecodeValidClaims
{
  NSData *claimsData = [FBSDKTypeUtility dataWithJSONObject:_claimsDict options:0 error:nil];
  NSString *encodedClaims = [self base64URLEncodeData:claimsData];

  FBSDKAuthenticationTokenClaims *claims = [FBSDKAuthenticationTokenClaims validatedClaimsWithEncodedString:encodedClaims nonce:_mockNonce];
  XCTAssertEqualObjects(claims, _claims);
}

- (void)testDecodeInvalidFormatClaims
{
  NSData *claimsData = [@"invalid_claims" dataUsingEncoding:NSUTF8StringEncoding];
  NSString *encodedClaims = [self base64URLEncodeData:claimsData];

  XCTAssertNil([FBSDKAuthenticationTokenClaims validatedClaimsWithEncodedString:encodedClaims nonce:_mockNonce]);
}

- (void)testDecodeInvalidClaims
{
  long currentTime = [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] longValue];

  // non facebook issuer
  [self assertDecodeClaimsFailWithInvalidEntry:@"iss"
                                         value:@"https://notfacebook.com"];
  [self assertDecodeClaimsFailWithInvalidEntry:@"iss"
                                         value:nil];
  [self assertDecodeClaimsFailWithInvalidEntry:@"iss"
                                         value:@""];

  // incorrect audience
  [self assertDecodeClaimsFailWithInvalidEntry:@"aud"
                                         value:@"wrong_app_id"];
  [self assertDecodeClaimsFailWithInvalidEntry:@"aud"
                                         value:nil];
  [self assertDecodeClaimsFailWithInvalidEntry:@"aud"
                                         value:@""];

  // expired
  [self assertDecodeClaimsFailWithInvalidEntry:@"exp"
                                         value:@(currentTime - 60 * 60)];
  [self assertDecodeClaimsFailWithInvalidEntry:@"exp"
                                         value:nil];
  [self assertDecodeClaimsFailWithInvalidEntry:@"exp"
                                         value:@""];

  // issued too long ago
  [self assertDecodeClaimsFailWithInvalidEntry:@"iat"
                                         value:@(currentTime - 60 * 60)];
  [self assertDecodeClaimsFailWithInvalidEntry:@"iat"
                                         value:nil];
  [self assertDecodeClaimsFailWithInvalidEntry:@"iat"
                                         value:@""];

  // incorrect nonce
  [self assertDecodeClaimsFailWithInvalidEntry:@"nonce"
                                         value:@"incorrect_nonce"];
  [self assertDecodeClaimsFailWithInvalidEntry:@"nonce"
                                         value:nil];
  [self assertDecodeClaimsFailWithInvalidEntry:@"nonce"
                                         value:@""];

  // invalid user ID
  [self assertDecodeClaimsFailWithInvalidEntry:@"sub"
                                         value:nil];
  [self assertDecodeClaimsFailWithInvalidEntry:@"sub"
                                         value:@""];

  // invalid JIT
  [self assertDecodeClaimsFailWithInvalidEntry:@"jti"
                                         value:nil];
  [self assertDecodeClaimsFailWithInvalidEntry:@"jti"
                                         value:@""];
}

- (void)testDecodeEmptyClaims
{
  NSDictionary *claims = @{};
  NSData *claimsData = [FBSDKTypeUtility dataWithJSONObject:claims options:0 error:nil];
  NSString *encodedClaims = [self base64URLEncodeData:claimsData];

  XCTAssertNil([FBSDKAuthenticationTokenClaims validatedClaimsWithEncodedString:encodedClaims nonce:_mockNonce]);
}

- (void)testDecodeRandomClaims
{
  for (int i = 0; i < 100; i++) {
    NSDictionary *randomizedClaims = [Fuzzer randomizeWithJson:_claims];
    NSData *claimsData = [FBSDKTypeUtility dataWithJSONObject:randomizedClaims options:0 error:nil];
    NSString *encodedClaims = [self base64URLEncodeData:claimsData];

    [FBSDKAuthenticationTokenClaims validatedClaimsWithEncodedString:encodedClaims nonce:_mockNonce];
  }
}

// MARK: - Decoding Header

- (void)testDecodeValidHeader
{
  NSData *headerData = [FBSDKTypeUtility dataWithJSONObject:_headerDict options:0 error:nil];
  NSString *encodedHeader = [self base64URLEncodeData:headerData];

  FBSDKAuthenticationTokenHeader *header = [FBSDKAuthenticationTokenHeader validatedHeaderWithEncodedString:encodedHeader];
  XCTAssertEqualObjects(header, _header);
}

- (void)testDecodeInvalidFormatHeader
{
  NSData *headerData = [@"invalid_header" dataUsingEncoding:NSUTF8StringEncoding];
  NSString *encodedHeader = [self base64URLEncodeData:headerData];

  XCTAssertNil([FBSDKAuthenticationTokenHeader validatedHeaderWithEncodedString:encodedHeader]);
}

- (void)testDecodeInvalidHeader
{
  NSMutableDictionary *invalidHeader = [_headerDict mutableCopy];
  [FBSDKTypeUtility dictionary:invalidHeader setObject:@"wrong algorithm" forKey:@"alg"];
  NSData *invalidHeaderData = [FBSDKTypeUtility dataWithJSONObject:invalidHeader options:0 error:nil];
  NSString *encodedHeader = [self base64URLEncodeData:invalidHeaderData];

  XCTAssertNil([FBSDKAuthenticationTokenHeader validatedHeaderWithEncodedString:encodedHeader]);
}

- (void)testDecodeEmptyHeader
{
  NSDictionary *header = @{};
  NSData *headerData = [FBSDKTypeUtility dataWithJSONObject:header options:0 error:nil];
  NSString *encodedHeader = [self base64URLEncodeData:headerData];

  XCTAssertNil([FBSDKAuthenticationTokenHeader validatedHeaderWithEncodedString:encodedHeader]);
}

- (void)testDecodeRandomHeader
{
  for (int i = 0; i < 100; i++) {
    NSDictionary *randomizedHeader = [Fuzzer randomizeWithJson:_headerDict];
    NSData *headerData = [FBSDKTypeUtility dataWithJSONObject:randomizedHeader options:0 error:nil];
    NSString *encodedHeader = [self base64URLEncodeData:headerData];

    [FBSDKAuthenticationTokenHeader validatedHeaderWithEncodedString:encodedHeader];
  }
}

// MARK: - Verifying Signature

- (void)testVerifySignatureWithoutDataWithoutResponseWithoutError
{
  FakeSessionDataTask *dataTask = [FakeSessionDataTask new];
  FakeSessionProvider *session = [FakeSessionProvider new];
  session.stubbedDataTask = dataTask;
  FBSDKAuthenticationTokenFactory *factory = [[FBSDKAuthenticationTokenFactory alloc] initWithSessionProvider:session];

  __block BOOL wasCalled = NO;
  [factory verifySignature:_signature
                    header:_encodedHeader
                    claims:_encodedClaims
            certificateKey:_certificateKey
                completion:^(BOOL success) {
                  XCTAssertFalse(
                    success,
                    "A signature cannot be verified if the certificate request returns no data"
                  );
                  wasCalled = YES;
                }];

  XCTAssertEqual(
    dataTask.resumeCallCount,
    1,
    "Should start the session data task when verifying a signature"
  );
  XCTAssertTrue(wasCalled);
}

- (void)testVerifySignatureWithDataWithInvalidResponseWithoutError
{
  FakeSessionDataTask *dataTask = [FakeSessionDataTask new];
  FakeSessionProvider *session = [FakeSessionProvider new];
  session.data = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
  session.urlResponse = [[NSHTTPURLResponse alloc] initWithURL:self.sampleURL statusCode:401 HTTPVersion:nil headerFields:nil];
  session.stubbedDataTask = dataTask;
  FBSDKAuthenticationTokenFactory *factory = [[FBSDKAuthenticationTokenFactory alloc] initWithSessionProvider:session];

  __block BOOL wasCalled = NO;
  [factory verifySignature:_signature
                    header:_encodedHeader
                    claims:_encodedClaims
            certificateKey:_certificateKey
                completion:^(BOOL success) {
                  XCTAssertFalse(
                    success,
                    "A signature cannot be verified if the certificate request returns a non-200 response"
                  );
                  wasCalled = YES;
                }];

  XCTAssertEqual(
    dataTask.resumeCallCount,
    1,
    "Should start the session data task when verifying a signature"
  );
  XCTAssertTrue(wasCalled);
}

- (void)testVerifySignatureWithInvalidDataWithValidResponseWithoutError
{
  FakeSessionDataTask *dataTask = [FakeSessionDataTask new];
  FakeSessionProvider *session = [FakeSessionProvider new];
  session.data = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
  session.urlResponse = [[NSHTTPURLResponse alloc] initWithURL:self.sampleURL statusCode:200 HTTPVersion:nil headerFields:nil];
  session.stubbedDataTask = dataTask;
  FBSDKAuthenticationTokenFactory *factory = [[FBSDKAuthenticationTokenFactory alloc] initWithSessionProvider:session];

  __block BOOL wasCalled = NO;
  [factory verifySignature:_signature
                    header:_encodedHeader
                    claims:_encodedClaims
            certificateKey:_certificateKey
                completion:^(BOOL success) {
                  XCTAssertFalse(
                    success,
                    "A signature cannot be verified if the certificate request returns invalid data"
                  );
                  wasCalled = YES;
                }];

  XCTAssertEqual(
    dataTask.resumeCallCount,
    1,
    "Should start the session data task when verifying a signature"
  );
  XCTAssertTrue(wasCalled);
}

- (void)testVerifySignatureWithValidDataWithValidResponseWithError
{
  FakeSessionDataTask *dataTask = [FakeSessionDataTask new];
  FakeSessionProvider *session = [FakeSessionProvider new];
  session.data = [self validCertificateData];
  session.urlResponse = [[NSHTTPURLResponse alloc] initWithURL:self.sampleURL statusCode:200 HTTPVersion:nil headerFields:nil];
  session.error = [self sampleError];
  session.stubbedDataTask = dataTask;
  FBSDKAuthenticationTokenFactory *factory = [[FBSDKAuthenticationTokenFactory alloc] initWithSessionProvider:session];

  __block BOOL wasCalled = NO;
  [factory verifySignature:_signature
                    header:_encodedHeader
                    claims:_encodedClaims
            certificateKey:_certificateKey
                completion:^(BOOL success) {
                  XCTAssertFalse(
                    success,
                    "A signature cannot be verified if the certificate request returns an error"
                  );
                  wasCalled = YES;
                }];

  XCTAssertEqual(
    dataTask.resumeCallCount,
    1,
    "Should start the session data task when verifying a signature"
  );
  XCTAssertTrue(wasCalled);
}

- (void)testVerifySignatureWithValidDataWithValidResponseWithoutError
{
  FakeSessionDataTask *dataTask = [FakeSessionDataTask new];
  FakeSessionProvider *session = [FakeSessionProvider new];
  session.data = [self validCertificateData];
  session.urlResponse = [[NSHTTPURLResponse alloc] initWithURL:self.sampleURL statusCode:200 HTTPVersion:nil headerFields:nil];
  session.stubbedDataTask = dataTask;
  FBSDKAuthenticationTokenFactory *factory = [[FBSDKAuthenticationTokenFactory alloc] initWithSessionProvider:session];

  __block BOOL wasCalled = NO;
  [factory verifySignature:_signature
                    header:_encodedHeader
                    claims:_encodedClaims
            certificateKey:_certificateKey
                completion:^(BOOL success) {
                  XCTAssertTrue(
                    success,
                    "Should verify a signature when the response contains the expected key"
                  );
                  wasCalled = YES;
                }];

  XCTAssertEqual(
    dataTask.resumeCallCount,
    1,
    "Should start the session data task when verifying a signature"
  );
  XCTAssertTrue(wasCalled);
}

- (void)testVerifySignatureWithFuzzyData
{
  FakeSessionDataTask *dataTask = [FakeSessionDataTask new];
  FakeSessionProvider *session = [FakeSessionProvider new];
  session.urlResponse = [[NSHTTPURLResponse alloc] initWithURL:self.sampleURL statusCode:200 HTTPVersion:nil headerFields:nil];
  session.stubbedDataTask = dataTask;
  FBSDKAuthenticationTokenFactory *factory = [[FBSDKAuthenticationTokenFactory alloc] initWithSessionProvider:session];

  for (int i = 0; i < 100; i++) {
    NSDictionary *randomizedCertificates = [Fuzzer randomizeWithJson:self.validRawCertificateResponse];
    NSData *data = [FBSDKTypeUtility dataWithJSONObject:randomizedCertificates options:0 error:nil];
    session.data = data;

    __block BOOL wasCalled = NO;
    [factory verifySignature:_signature
                      header:_encodedHeader
                      claims:_encodedClaims
              certificateKey:_certificateKey
                  completion:^(BOOL success) {
                    wasCalled = YES;
                  }];
    XCTAssertTrue(wasCalled);
  }
}

// MARK: - Helpers

- (void)assertDecodeClaimsFailWithInvalidEntry:(NSString *)key value:(id)value
{
  NSMutableDictionary *invalidClaims = [_claimsDict mutableCopy];
  if (value) {
    [FBSDKTypeUtility dictionary:invalidClaims setObject:value forKey:key];
  } else {
    [invalidClaims removeObjectForKey:key];
  }

  NSData *claimsData = [FBSDKTypeUtility dataWithJSONObject:invalidClaims options:0 error:nil];
  NSString *encodedClaims = [self base64URLEncodeData:claimsData];

  XCTAssertNil([FBSDKAuthenticationTokenClaims validatedClaimsWithEncodedString:encodedClaims nonce:_mockNonce]);
}

- (NSString *)base64URLEncodeData:(NSData *)data
{
  NSString *base64 = [FBSDKBase64 encodeData:data];
  NSString *base64URL = [base64 stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
  base64URL = [base64URL stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
  return [base64URL stringByReplacingOccurrencesOfString:@"=" withString:@""];
}

- (NSDictionary *)validRawCertificateResponse
{
  return @{
    _certificateKey : _certificate,
    @"foo" : @"Not a certificate"
  };
}

- (NSData *)validCertificateData
{
  return [FBSDKTypeUtility dataWithJSONObject:self.validRawCertificateResponse options:0 error:nil];
}

- (NSURL *)sampleURL
{
  return [NSURL URLWithString:@"https://example.com"];
}

- (NSError *)sampleError
{
  return [NSError errorWithDomain:self.name code:0 userInfo:nil];
}

@end
