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

#import "FBSDKAuthenticationTokenClaims+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKSettings;

@interface FBSDKAuthenticationTokenClaims (Testing)

@property (class, nullable, nonatomic, readonly) id<FBSDKSettings> settings;

+ (void)configureWithSettings:(nonnull id<FBSDKSettings>)settings
NS_SWIFT_NAME(configure(settings:));

+ (void)configureClassDependencies;

+ (void)resetClassDependencies;

- (nullable instancetype)initWithJti:(nonnull NSString *)jti
                                 iss:(nonnull NSString *)iss
                                 aud:(nonnull NSString *)aud
                               nonce:(nonnull NSString *)nonce
                                 exp:(NSTimeInterval)exp
                                 iat:(NSTimeInterval)iat
                                 sub:(nonnull NSString *)sub
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

@end

NS_ASSUME_NONNULL_END
