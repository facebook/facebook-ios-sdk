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

#import "FBSDKAuthenticationTokenClaims.h"

#import "FBSDKCoreKitBasicsImport.h"
#import "FBSDKSettings.h"

static long const MaxTimeSinceTokenIssued = 10 * 60; // 10 mins

@implementation FBSDKAuthenticationTokenClaims

- (instancetype)initWithJti:(NSString *)jti
                        iss:(NSString *)iss
                        aud:(NSString *)aud
                      nonce:(NSString *)nonce
                        exp:(long)exp
                        iat:(long)iat
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
                   userLink:(nullable NSString *)userLink
{
  if (self = [super init]) {
    _jti = jti;
    _iss = iss;
    _aud = aud;
    _nonce = nonce;
    _exp = exp;
    _iat = iat;
    _sub = sub;
    _name = name;
    _givenName = givenName;
    _middleName = middleName;
    _familyName = familyName;
    _email = email;
    _picture = picture;
    _userFriends = userFriends;
    _userBirthday = userBirthday;
    _userAgeRange = userAgeRange;
    _userHometown = userHometown;
    _userLocation = userLocation;
    _userGender = userGender;
    _userLink = userLink;
  }

  return self;
}

+ (nullable FBSDKAuthenticationTokenClaims *)claimsFromEncodedString:(NSString *)encodedClaims nonce:(NSString *)expectedNonce
{
  NSError *error;
  NSData *claimsData = [FBSDKBase64 decodeAsData:[FBSDKBase64 base64FromBase64Url:encodedClaims]];

  if (claimsData) {
    NSDictionary *claimsDict = [FBSDKTypeUtility JSONObjectWithData:claimsData options:0 error:&error];
    if (!error) {
      long currentTime = [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] longValue];

      // verify claims
      NSString *jti = [FBSDKTypeUtility coercedToStringValue:claimsDict[@"jti"]];
      BOOL hasJti = jti.length > 0;

      NSString *iss = [FBSDKTypeUtility coercedToStringValue:claimsDict[@"iss"]];
      BOOL isFacebook = iss.length > 0 && [[[NSURL URLWithString:iss] host] isEqualToString:@"facebook.com"];

      NSString *aud = [FBSDKTypeUtility coercedToStringValue:claimsDict[@"aud"]];
      BOOL audMatched = [aud isEqualToString:[FBSDKSettings appID]];

      NSNumber *expValue = [FBSDKTypeUtility numberValue:claimsDict[@"exp"]];
      long exp = [expValue doubleValue];
      BOOL isExpired = expValue == nil || exp <= currentTime;

      NSNumber *iatValue = [FBSDKTypeUtility numberValue:claimsDict[@"iat"]];
      long iat = [iatValue doubleValue];
      BOOL issuedRecently = iatValue != nil && iat >= currentTime - MaxTimeSinceTokenIssued;

      NSString *nonce = [FBSDKTypeUtility coercedToStringValue:claimsDict[@"nonce"]];
      BOOL nonceMatched = nonce.length > 0 && [nonce isEqualToString:expectedNonce];

      NSString *sub = [FBSDKTypeUtility coercedToStringValue:claimsDict[@"sub"]];
      BOOL userIDValid = sub.length > 0;

      NSString *name = [FBSDKTypeUtility coercedToStringValue:claimsDict[@"name"]];
      NSString *givenName = [FBSDKTypeUtility coercedToStringValue:claimsDict[@"given_name"]];
      NSString *middleName = [FBSDKTypeUtility coercedToStringValue:claimsDict[@"middle_name"]];
      NSString *familyName = [FBSDKTypeUtility coercedToStringValue:claimsDict[@"family_name"]];
      NSString *email = [FBSDKTypeUtility coercedToStringValue:claimsDict[@"email"]];
      NSString *picture = [FBSDKTypeUtility coercedToStringValue:claimsDict[@"picture"]];
      NSString *userBirthday = [FBSDKTypeUtility coercedToStringValue:claimsDict[@"user_birthday"]];

      NSMutableDictionary<NSString *, NSNumber *> *userAgeRange;
      NSDictionary *rawUserAgeRange = [FBSDKTypeUtility dictionaryValue:claimsDict[@"user_age_range"]];
      if (rawUserAgeRange.count > 0) {
        userAgeRange = NSMutableDictionary.new;
        for (NSString *key in rawUserAgeRange) {
          NSNumber *value = [FBSDKTypeUtility dictionary:rawUserAgeRange objectForKey:key ofType:NSNumber.class];
          if (value == nil) {
            userAgeRange = nil;
            break;
          }

          [FBSDKTypeUtility dictionary:userAgeRange setObject:value forKey:key];
        }
      }

      NSMutableDictionary<NSString *, NSString *> *userHometown = [self extractLocationDictFromClaims:claimsDict key:@"user_hometown"];
      NSMutableDictionary<NSString *, NSString *> *userLocation = [self extractLocationDictFromClaims:claimsDict key:@"user_location"];

      NSString *userGender = [FBSDKTypeUtility coercedToStringValue:claimsDict[@"user_gender"]];
      NSString *userLink = [FBSDKTypeUtility coercedToStringValue:claimsDict[@"user_link"]];

      NSArray<NSString *> *userFriends = [FBSDKTypeUtility arrayValue:claimsDict[@"user_friends"]];
      for (NSString *friend in userFriends) {
        if (![FBSDKTypeUtility coercedToStringValue:friend]) {
          userFriends = nil;
          break;
        }
      }

      if (hasJti && isFacebook && audMatched && !isExpired && issuedRecently && nonceMatched && userIDValid) {
        return [[FBSDKAuthenticationTokenClaims alloc] initWithJti:jti
                                                               iss:iss
                                                               aud:aud
                                                             nonce:nonce
                                                               exp:exp
                                                               iat:iat
                                                               sub:sub
                                                              name:name
                                                         givenName:givenName
                                                        middleName:middleName
                                                        familyName:familyName
                                                             email:email
                                                           picture:picture
                                                       userFriends:userFriends
                                                      userBirthday:userBirthday
                                                      userAgeRange:userAgeRange
                                                      userHometown:userHometown
                                                      userLocation:userLocation
                                                        userGender:userGender
                                                          userLink:userLink];
      }
    }
  }

  return nil;
}

+ (nullable NSMutableDictionary<NSString *, NSString *> *)extractLocationDictFromClaims:(NSDictionary *)claimsDict key:(NSString *)keyName
{
  NSDictionary *rawLocationData = [FBSDKTypeUtility dictionaryValue:claimsDict[keyName]];
  NSMutableDictionary<NSString *, NSString *> *location;
  if (rawLocationData.count > 0) {
    location = NSMutableDictionary.new;
    for (NSString *key in rawLocationData) {
      NSString *value = [FBSDKTypeUtility dictionary:rawLocationData
                                        objectForKey:key
                                              ofType:NSString.class];
      if (value == nil) {
        return nil;
      }

      [FBSDKTypeUtility dictionary:location setObject:value forKey:key];
    }
  }
  return location;
}

// MARK: Equality

- (BOOL)isEqualToClaims:(FBSDKAuthenticationTokenClaims *)claims
{
  return [_jti isEqualToString:claims.jti]
  && [_iss isEqualToString:claims.iss]
  && [_aud isEqualToString:claims.aud]
  && [_nonce isEqualToString:claims.nonce]
  && _exp == claims.exp
  && _iat == claims.iat
  && [_sub isEqualToString:claims.sub]
  && [_name isEqualToString:claims.name]
  && [_givenName isEqualToString:claims.givenName]
  && [_middleName isEqualToString:claims.middleName]
  && [_familyName isEqualToString:claims.familyName]
  && [_email isEqualToString:claims.email]
  && [_picture isEqualToString:claims.picture]
  && [_userFriends isEqualToArray:claims.userFriends]
  && [_userBirthday isEqualToString:claims.userBirthday]
  && [_userAgeRange isEqualToDictionary:claims.userAgeRange]
  && [_userHometown isEqualToDictionary:claims.userHometown]
  && [_userLocation isEqualToDictionary:claims.userLocation]
  && [_userGender isEqualToString:claims.userGender]
  && [_userLink isEqualToString:claims.userLink];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[FBSDKAuthenticationTokenClaims class]]) {
    return NO;
  }

  return [self isEqualToClaims:(FBSDKAuthenticationTokenClaims *)object];
}

@end
