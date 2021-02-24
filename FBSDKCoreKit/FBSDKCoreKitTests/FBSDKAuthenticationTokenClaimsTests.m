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

#import "FBSDKCoreKit.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKTestCase.h"

static NSString *const _mockAppID = @"4321";
static NSString *const _mockJTI = @"some_jti";
static NSString *const _mockNonce = @"some_nonce";
static NSString *const _facebookURL = @"https://facebook.com/dialog/oauth";

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
                    picture:(nullable NSString *)picture
                userFriends:(nullable NSArray<NSString *> *)userFriends;

+ (nullable FBSDKAuthenticationTokenClaims *)claimsFromEncodedString:(NSString *)encodedClaims nonce:(NSString *)expectedNonce;

@end

@interface FBSDKAuthenticationTokenClaimsTests : FBSDKTestCase

@end

@implementation FBSDKAuthenticationTokenClaimsTests
{
  FBSDKAuthenticationTokenClaims *_claims;
  NSDictionary *_claimsDict;
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
                                                        picture:@"https://www.facebook.com/some_picture"
                                                    userFriends:@[@"1122", @"3344", @"5566"]
  ];

  _claimsDict = [self dictionaryFromClaims:_claims];
}

// MARK: - Decoding Claims

- (void)testDecodeValidClaims
{
  NSData *claimsData = [FBSDKTypeUtility dataWithJSONObject:_claimsDict options:0 error:nil];
  NSString *encodedClaims = [self base64URLEncodeData:claimsData];

  FBSDKAuthenticationTokenClaims *claims = [FBSDKAuthenticationTokenClaims claimsFromEncodedString:encodedClaims nonce:_mockNonce];
  XCTAssertEqualObjects(claims, _claims);
}

- (void)testDecodeInvalidFormatClaims
{
  NSData *claimsData = [@"invalid_claims" dataUsingEncoding:NSUTF8StringEncoding];
  NSString *encodedClaims = [self base64URLEncodeData:claimsData];

  XCTAssertNil([FBSDKAuthenticationTokenClaims claimsFromEncodedString:encodedClaims nonce:_mockNonce]);
}

- (void)testDecodeClaimsWithInvalidRequiredClaims
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

- (void)testDecodeClaimsWithInvalidOptionalClaims
{
  for (NSString *claim in @[@"name", @"email", @"picture", @"user_friends"]) {
    [self assertDecodeClaimsDropInvalidEntry:claim value:nil];
    [self assertDecodeClaimsDropInvalidEntry:claim value:[NSDictionary new]];
  }

  [self assertDecodeClaimsDropInvalidEntry:@"user_friends" value:@[[NSDictionary new]]];
}

- (void)testDecodeEmptyClaims
{
  NSDictionary *claims = @{};
  NSData *claimsData = [FBSDKTypeUtility dataWithJSONObject:claims options:0 error:nil];
  NSString *encodedClaims = [self base64URLEncodeData:claimsData];

  XCTAssertNil([FBSDKAuthenticationTokenClaims claimsFromEncodedString:encodedClaims nonce:_mockNonce]);
}

- (void)testDecodeRandomClaims
{
  for (int i = 0; i < 100; i++) {
    NSDictionary *randomizedClaims = [Fuzzer randomizeWithJson:_claims];
    NSData *claimsData = [FBSDKTypeUtility dataWithJSONObject:randomizedClaims options:0 error:nil];
    NSString *encodedClaims = [self base64URLEncodeData:claimsData];

    [FBSDKAuthenticationTokenClaims claimsFromEncodedString:encodedClaims nonce:_mockNonce];
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

  XCTAssertNil([FBSDKAuthenticationTokenClaims claimsFromEncodedString:encodedClaims nonce:_mockNonce]);
}

- (void)assertDecodeClaimsDropInvalidEntry:(NSString *)key value:(id)value
{
  NSMutableDictionary *invalidClaims = [_claimsDict mutableCopy];
  if (value) {
    [FBSDKTypeUtility dictionary:invalidClaims setObject:value forKey:key];
  } else {
    [invalidClaims removeObjectForKey:key];
  }

  NSData *claimsData = [FBSDKTypeUtility dataWithJSONObject:invalidClaims options:0 error:nil];
  NSString *encodedClaims = [self base64URLEncodeData:claimsData];

  FBSDKAuthenticationTokenClaims *actualClaims = [FBSDKAuthenticationTokenClaims claimsFromEncodedString:encodedClaims nonce:_mockNonce];
  XCTAssertNotNil(actualClaims);
  XCTAssertNil([self dictionaryFromClaims:actualClaims][key]);
}

- (NSString *)base64URLEncodeData:(NSData *)data
{
  NSString *base64 = [FBSDKBase64 encodeData:data];
  NSString *base64URL = [base64 stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
  base64URL = [base64URL stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
  return [base64URL stringByReplacingOccurrencesOfString:@"=" withString:@""];
}

- (NSDictionary *)dictionaryFromClaims:(FBSDKAuthenticationTokenClaims *)claims
{
  NSMutableDictionary *dict = [NSMutableDictionary new];
  [dict setValue:claims.iss forKey:@"iss"];
  [dict setValue:claims.aud forKey:@"aud"];
  [dict setValue:claims.nonce forKey:@"nonce"];
  [dict setValue:@(claims.exp) forKey:@"exp"];
  [dict setValue:@(claims.iat) forKey:@"iat"];
  [dict setValue:@(claims.exp) forKey:@"exp"];
  [dict setValue:claims.jti forKey:@"jti"];
  [dict setValue:claims.sub forKey:@"sub"];
  [dict setValue:claims.name forKey:@"name"];
  [dict setValue:claims.email forKey:@"email"];
  [dict setValue:claims.picture forKey:@"picture"];
  [dict setValue:claims.userFriends forKey:@"user_friends"];

  return dict;
}

@end
