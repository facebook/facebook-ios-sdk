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

#import <TestTools/TestTools-Swift.h>

#import "FBSDKLoginKitTests-Swift.h"

static NSString *const _certificate = @"-----BEGIN CERTIFICATE-----\nMIIDgjCCAmoCCQDMso+U6N9AMjANBgkqhkiG9w0BAQsFADCBgjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAldBMRAwDgYDVQQHDAdTZWF0dGxlMREwDwYDVQQKDAhGYWNlYm9vazEMMAoGA1UECwwDRW5nMRIwEAYDVQQDDAlwYW5zeTA0MTkxHzAdBgkqhkiG9w0BCQEWEHBhbnN5MDQxOUBmYi5jb20wHhcNMjAxMTAzMDAzNTI1WhcNMzAxMTAxMDAzNTI1WjCBgjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAldBMRAwDgYDVQQHDAdTZWF0dGxlMREwDwYDVQQKDAhGYWNlYm9vazEMMAoGA1UECwwDRW5nMRIwEAYDVQQDDAlwYW5zeTA0MTkxHzAdBgkqhkiG9w0BCQEWEHBhbnN5MDQxOUBmYi5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD0R8/zzuJ5SM+8KBgshg+sKARfm4Ad7Qv7Vi0L8xoXpReXxefDHF7jI9o6pLsp5OIEmnhRjTlbdT7APK1pZ8dHjOdod6xWSoQigUplYOqa5iuVx7IqD15PUhx6/LqcAtHFKDtKOPuIc8CqkmVUyGRMq2OxdCoiWix5z79pSDILmlRWsn4UOCpFU/Ix75YL/JD19IHgwgh4XCxDwUVhmpgG+jI5l9a3ZCBx7JwZAoJ/Z/OpVbguAlBnxIpi8Qk5VKdHzLHvkrdGXGFMzao6bReXX3KNrYrurAgd7fD2TAQo8EH5rgB7ewxtCIlHRoXJPSdVKpTPwx4c7Mfu2EMpx66pAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAPKMCK6mlLIFxMvIa4lT3fYY+APPhMazHtiPJ+279dkhzGmugD3x+mWvd+OzdmWlW/bvZWLbG3UXA166FK8ZcYyuTYdhCxP3vRNqBWNC65qURnIYyUK2DT09WrvBWLZqhv/mJFfijnGqvkKA1k3rVtgCGNDEnezmC9uuO8P17y3+/RZY8dBfvd8lkdCyTCFnKHNyKAE83qnqAJwgbc7cv7IKwAYsDdr4u38GFayBdTzCatTVrQDTYZbJDJLx+BcvHw8pdhthsX7wpGbFH5++Y5G4hRF2vGenzLFIHthxFnpgiZO3VjloPB57awA4jmJY9DjsOZNhZT+RbnCO9AQlCZE=\n-----END CERTIFICATE-----";
static NSString *const _incorrectCertificate = @"-----BEGIN CERTIFICATE-----\nMIIDATCCAemgAwIBAgIJAO+h3vH3X1puMA0GCSqGSIb3DQEBCwUAMBcxFTATBgNV\nBAMMDGZhY2Vib29rLmNvbTAeFw0yMDExMTAwMTUzMTFaFw0yMTA1MDkwMTUzMTFa\nMBcxFTATBgNVBAMMDGZhY2Vib29rLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEP\nADCCAQoCggEBAOZH/FVV1nsdlg6vhjuQlK8VYbN7F+aFAnkMFKQV+MQ88qj/zyBS\nAGZy5MTB3zHjCjw0IhJxTYoESxLy12T7UWqM7ltyKgEO0d8lLbIXR07QWziMd1Q+\n1AlTG9Yj6cMzQGFceB9x09MrOz/Gg+YrIzuRI2TXCaDW7j4LBhqLAlVrK8aMOVHJ\nFDWVCxuwdSNuJ+FNo/bvUqAWVQtn7KNoOcbot5Y4KAVQ16nufH0dJtRcOHzNELYB\nbxmtLWC8eKNn3H8Yw4whZV2BCVZJ/dQ1HZVlSktSs1wE5amg4wm3rHffyN1fpTah\nvN6bjMCQHrpBH2r0BSrkai/joh2ZeWZC068CAwEAAaNQME4wHQYDVR0OBBYEFIYZ\nJeio2kloli49hq+idEeGz3WwMB8GA1UdIwQYMBaAFIYZJeio2kloli49hq+idEeG\nz3WwMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBADU9ODtwRL7YDCJ6\naem7juewkgnXx48Tzcl6JtJijIl+IK0Phzb9r/GYrSC+H/N5rWCK5Ur55owXidb9\nXuLysM9xfHBUv91BK03XpevA0bwXCfRk0KPgyc744b8Qb636QiUOzF2aQTYxXbSF\nmXj1HdREsKow0202LfhjKtQWbL+7Q3lpiOFFOkkEVCBu42LT/Ix8VuL/RF3I2xS0\nBhO7FK6Y+ppw33lcmwfP7lLROpeowZA1WeF6tDsqBYivGg8G+9abAMnW0s4ZZSGD\ncDpGIcIlBRhr4nNo0u11BYuxcY8fukYkHvDYygrNhLVNme7JO3Iix7SOyxeMgT9t\ntBi+u9M=\n-----END CERTIFICATE-----";
static NSString *const _encodedHeader = @"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9";
static NSString *const _encodedClaims = @"eyJzdWIiOiIxMjM0IiwibmFtZSI6IlRlc3QgVXNlciIsImlzcyI6Imh0dHBzOi8vZmFjZWJvb2suY29tL2RpYWxvZy9vYXV0aCIsImF1ZCI6IjQzMjEiLCJub25jZSI6InNvbWVfbm9uY2UiLCJleHAiOjE1MTYyNTkwMjIsImVtYWlsIjoiZW1haWxAZW1haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vd3d3LmZhY2Vib29rLmNvbS9zb21lX3BpY3R1cmUiLCJpYXQiOjE1MTYyMzkwMjJ9";
static NSString *const _signature = @"rTaqfx5Dz0UbzxZ3vBhitgtetWKBJ3-egz5n6l4ngLYqQ7ywapDvS7cM1NRGAh9drT8QeoxKPm0H_1B1LJBNyx-Fiseetfs7XANuocwTx9k7so3bi_EW0V-RYoDTgg5asS9Ra2qYM829xMYkhBHXp1HwHo0uHz1tafQ1hTsxtzH29t23_EnPpnVx5jvu-UeAEL4Q7VeIIfkweQYzuT3cowWAs-Vhyvl9I39Z4Uh_3ZhkpBJW1CblPW3ekHoySC61qwePM9Fk0q3N7K45LtktIMR5biV0RvJceTGOssHGhjaQ3hzpRq318MZKfBtg6C-Ryhh8SmOkuDrrj-VNdoVHKg";
static NSString *const _certificateKey = @"some_key";

typedef void (^FBSDKVerifySignatureCompletionBlock)(BOOL success);

@interface FBSDKAuthenticationTokenFactory (Testing)

- (instancetype)initWithSessionProvider:(id<FBSDKSessionProviding>)sessionProvider;
- (void)setCertificate:(NSString *)certificate;
- (BOOL)verifySignature:(NSString *)signature
                 header:(NSString *)header
                 claims:(NSString *)claims
         certificateKey:(NSString *)key
             completion:(FBSDKVerifySignatureCompletionBlock)completion;
- (NSDictionary<NSString *, id> *)claims;
- (NSURL *)_certificateEndpoint;

@end

@interface FBSDKAuthenticationTokenFactoryTests : XCTestCase

@end

@implementation FBSDKAuthenticationTokenFactoryTests

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

// MARK: - Verifying Signature

- (void)testCertificateEndpointURL
{
  NSURL *url = FBSDKAuthenticationTokenFactory.new._certificateEndpoint;
  XCTAssertEqualObjects(url.absoluteString, @"https://m.facebook.com/.well-known/oauth/openid/certs/");
}

- (void)testVerifySignatureWithoutDataWithoutResponseWithoutError
{
  TestSessionDataTask *dataTask = [TestSessionDataTask new];
  TestSessionProvider *session = [TestSessionProvider new];
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

  session.capturedCompletion(nil, nil, nil);
  XCTAssertTrue(wasCalled);
}

- (void)testVerifySignatureWithDataWithInvalidResponseWithoutError
{
  TestSessionDataTask *dataTask = [TestSessionDataTask new];
  TestSessionProvider *session = [TestSessionProvider new];
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

  session.capturedCompletion(
    [@"foo" dataUsingEncoding:NSUTF8StringEncoding],
    [[NSHTTPURLResponse alloc] initWithURL:self.sampleURL statusCode:401 HTTPVersion:nil headerFields:nil],
    nil
  );
  XCTAssertTrue(wasCalled);
}

- (void)testVerifySignatureWithInvalidDataWithValidResponseWithoutError
{
  TestSessionDataTask *dataTask = [TestSessionDataTask new];
  TestSessionProvider *session = [TestSessionProvider new];
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

  session.capturedCompletion(
    [@"foo" dataUsingEncoding:NSUTF8StringEncoding],
    [[NSHTTPURLResponse alloc] initWithURL:self.sampleURL statusCode:200 HTTPVersion:nil headerFields:nil],
    nil
  );
  XCTAssertTrue(wasCalled);
}

- (void)testVerifySignatureWithValidDataWithValidResponseWithError
{
  TestSessionDataTask *dataTask = [TestSessionDataTask new];
  TestSessionProvider *session = [TestSessionProvider new];
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

  session.capturedCompletion(
    [self validCertificateData],
    [[NSHTTPURLResponse alloc] initWithURL:self.sampleURL statusCode:200 HTTPVersion:nil headerFields:nil],
    [self sampleError]
  );
  XCTAssertTrue(wasCalled);
}

- (void)testVerifySignatureWithValidDataWithValidResponseWithoutError
{
  TestSessionDataTask *dataTask = [TestSessionDataTask new];
  TestSessionProvider *session = [TestSessionProvider new];
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
  session.capturedCompletion(
    [self validCertificateData],
    [[NSHTTPURLResponse alloc] initWithURL:self.sampleURL statusCode:200 HTTPVersion:nil headerFields:nil],
    nil
  );

  XCTAssertTrue(wasCalled);
}

- (void)testVerifySignatureWithInvalidCertificates
{
  NSArray *certificates = @[
    [self mangledCertificateData],
    [self validIncorrectCertificateData]
  ];

  for (NSData *certificateData in certificates) {
    TestSessionDataTask *dataTask = [TestSessionDataTask new];
    TestSessionProvider *session = [TestSessionProvider new];
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
                      "Should not verify a signature for an incorrect or invalid certificate"
                    );
                    wasCalled = YES;
                  }];
    XCTAssertEqual(
      dataTask.resumeCallCount,
      1,
      "Should start the session data task when verifying a signature"
    );
    session.capturedCompletion(
      certificateData,
      [[NSHTTPURLResponse alloc] initWithURL:self.sampleURL statusCode:200 HTTPVersion:nil headerFields:nil],
      nil
    );
    XCTAssertTrue(wasCalled);
  }
}

- (void)testVerifySignatureWithFuzzyData
{
  TestSessionDataTask *dataTask = [TestSessionDataTask new];
  TestSessionProvider *session = [TestSessionProvider new];
  session.stubbedDataTask = dataTask;
  FBSDKAuthenticationTokenFactory *factory = [[FBSDKAuthenticationTokenFactory alloc] initWithSessionProvider:session];

  for (int i = 0; i < 100; i++) {
    NSDictionary<NSString *, id> *randomizedCertificates = [Fuzzer randomizeWithJson:self.validRawCertificateResponse];
    __block BOOL wasCalled = NO;
    [factory verifySignature:_signature
                      header:_encodedHeader
                      claims:_encodedClaims
              certificateKey:_certificateKey
                  completion:^(BOOL success) {
                    wasCalled = YES;
                  }];
    session.capturedCompletion(
      [FBSDKTypeUtility dataWithJSONObject:randomizedCertificates options:0 error:nil],
      [[NSHTTPURLResponse alloc] initWithURL:self.sampleURL statusCode:200 HTTPVersion:nil headerFields:nil],
      nil
    );
    XCTAssertTrue(wasCalled);
  }
}

// MARK: - Helpers

- (NSDictionary<NSString *, id> *)validRawCertificateResponse
{
  return @{
    _certificateKey : _certificate,
    @"foo" : @"Not a certificate"
  };
}

- (NSData *)mangledCertificateData
{
  NSString *mangledCertificate = [_certificate stringByReplacingOccurrencesOfString:@"a" withString:@"b"];
  NSDictionary<NSString *, id> *certificates = @{
    _certificateKey : mangledCertificate
  };

  return [FBSDKTypeUtility dataWithJSONObject:certificates options:0 error:nil];
}

- (NSData *)validCertificateData
{
  return [FBSDKTypeUtility dataWithJSONObject:self.validRawCertificateResponse options:0 error:nil];
}

- (NSData *)validIncorrectCertificateData
{
  NSDictionary<NSString *, id> *certificates = @{
    _certificateKey : _incorrectCertificate
  };

  return [FBSDKTypeUtility dataWithJSONObject:certificates options:0 error:nil];
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
