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

static NSString *const _mockAppID = @"4321";
static NSString *const _mockJTI = @"some_jti";
static NSString *const _mockNonce = @"some_nonce";
static NSString *const _facebookURL = @"https://facebook.com/dialog/oauth";

@interface FBSDKAuthenticationTokenClaims (Testing)

- (instancetype)initWithJti:(NSString *)jti
                        iss:(NSString *)iss
                        aud:(NSString *)aud
                      nonce:(NSString *)nonce
                        exp:(NSTimeInterval)exp
                        iat:(NSTimeInterval)iat
                        sub:(NSString *)sub
                       name:(nullable NSString *)name
                  givenName:(nullable NSString *)givenName
                 middleName:(nullable NSString *)middleName
                 familyName:(nullable NSString *)familyName
                      email:(nullable NSString *)email
                    picture:(nullable NSString *)picture
                userFriends:(nullable NSArray<NSString *> *)userFriends
               userBirthday:(nullable NSString *)userBirthday
               userAgeRange:(nullable NSDictionary<NSString *, NSNumber *> *)userAgeRange
               userHometown:(nullable NSDictionary<NSString *, NSString *> *)userHometown
               userLocation:(nullable NSDictionary<NSString *, NSString *> *)userLocation
                 userGender:(nullable NSString *)userGender
                   userLink:(nullable NSString *)userLink;

+ (nullable FBSDKAuthenticationTokenClaims *)claimsFromEncodedString:(NSString *)encodedClaims nonce:(NSString *)expectedNonce;

@end

@interface FBSDKAuthenticationTokenClaimsTests : XCTestCase

@end

@implementation FBSDKAuthenticationTokenClaimsTests
{
  FBSDKAuthenticationTokenClaims *_claims;
  NSDictionary *_claimsDict;
}

- (void)setUp
{
  [super setUp];

  [FBSDKSettings reset];
  [TestAppEventsConfigurationProvider reset];
  [FBSDKSettings configureWithStore:[UserDefaultsSpy new]
     appEventsConfigurationProvider:TestAppEventsConfigurationProvider.class
             infoDictionaryProvider:[TestBundle new]
                        eventLogger:[TestAppEvents new]];

  FBSDKSettings.appID = _mockAppID;

  long currentTime = [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] longValue];

  _claims = [[FBSDKAuthenticationTokenClaims alloc] initWithJti:_mockJTI
                                                            iss:_facebookURL
                                                            aud:_mockAppID
                                                          nonce:_mockNonce
                                                            exp:currentTime + 60 * 60 * 48 // 2 days later
                                                            iat:currentTime - 60 // 1 min ago
                                                            sub:@"1234"
                                                           name:@"Test User"
                                                      givenName:@"Test"
                                                     middleName:@"Middle"
                                                     familyName:@"User"
                                                          email:@"email@email.com"
                                                        picture:@"https://www.facebook.com/some_picture"
                                                    userFriends:@[@"1122", @"3344", @"5566"]
                                                   userBirthday:@"01/01/1990"
                                                   userAgeRange:@{@"min" : @(21)}
                                                   userHometown:@{@"id" : @"112724962075996", @"name" : @"Martinez, California"}
                                                   userLocation:@{@"id" : @"110843418940484", @"name" : @"Seattle, Washington"}
                                                     userGender:@"male"
                                                       userLink:@"facebook.com"
  ];

  _claimsDict = [self dictionaryFromClaims:_claims];
}

- (void)tearDown
{
  [super tearDown];

  [FBSDKSettings reset];
  [TestAppEventsConfigurationProvider reset];
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
  for (NSString *claim in @[@"name", @"given_name", @"middle_name", @"family_name", @"email", @"picture", @"user_friends", @"user_birthday", @"user_age_range", @"user_hometown", @"user_location", @"user_gender", @"user_link"]) {
    [self assertDecodeClaimsDropInvalidEntry:claim value:nil];
    [self assertDecodeClaimsDropInvalidEntry:claim value:NSDictionary.new];
  }

  [self assertDecodeClaimsDropInvalidEntry:@"user_friends" value:@[[NSDictionary new]]];

  [self assertDecodeClaimsDropInvalidEntry:@"user_age_range" value:@""];
  [self assertDecodeClaimsDropInvalidEntry:@"user_age_range" value:@{@"min" : @(123), @"max" : @"test"}];
  [self assertDecodeClaimsDropInvalidEntry:@"user_age_range" value:@{}];

  [self assertDecodeClaimsDropInvalidEntry:@"user_hometown" value:@{@"id" : @(123), @"name" : @"test"}];
  [self assertDecodeClaimsDropInvalidEntry:@"user_hometown" value:@""];
  [self assertDecodeClaimsDropInvalidEntry:@"user_hometown" value:@{}];

  [self assertDecodeClaimsDropInvalidEntry:@"user_location" value:@{@"id" : @(123), @"name" : @"test"}];
  [self assertDecodeClaimsDropInvalidEntry:@"user_location" value:@""];
  [self assertDecodeClaimsDropInvalidEntry:@"user_location" value:@{}];
}

- (void)testDecodeClaimsWithEmptyFriendsList
{
  NSMutableDictionary *claims = [_claimsDict mutableCopy];
  [FBSDKTypeUtility dictionary:claims setObject:@[] forKey:@"user_friends"];

  NSData *claimsData = [FBSDKTypeUtility dataWithJSONObject:claims options:0 error:nil];
  NSString *encodedClaims = [self base64URLEncodeData:claimsData];

  FBSDKAuthenticationTokenClaims *actualClaims = [FBSDKAuthenticationTokenClaims claimsFromEncodedString:encodedClaims nonce:_mockNonce];
  XCTAssertEqualObjects(actualClaims.userFriends, @[]);
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
  [dict setValue:claims.givenName forKey:@"given_name"];
  [dict setValue:claims.middleName forKey:@"middle_name"];
  [dict setValue:claims.familyName forKey:@"family_name"];
  [dict setValue:claims.email forKey:@"email"];
  [dict setValue:claims.picture forKey:@"picture"];
  [dict setValue:claims.userFriends forKey:@"user_friends"];
  [dict setValue:claims.userBirthday forKey:@"user_birthday"];
  [dict setValue:claims.userAgeRange forKey:@"user_age_range"];
  [dict setValue:claims.userHometown forKey:@"user_hometown"];
  [dict setValue:claims.userLocation forKey:@"user_location"];
  [dict setValue:claims.userGender forKey:@"user_gender"];
  [dict setValue:claims.userLink forKey:@"user_link"];

  return dict;
}

@end
