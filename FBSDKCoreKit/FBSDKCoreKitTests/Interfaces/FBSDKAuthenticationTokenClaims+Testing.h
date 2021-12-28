/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAuthenticationTokenClaims+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKSettings;

@interface FBSDKAuthenticationTokenClaims (Testing)

@property (class, nullable, nonatomic, readonly) id<FBSDKSettings> settings;

// UNCRUSTIFY_FORMAT_OFF
+ (void)configureWithSettings:(nonnull id<FBSDKSettings>)settings
NS_SWIFT_NAME(configure(settings:));
// UNCRUSTIFY_FORMAT_ON

+ (void)configureClassDependencies;

#if FBTEST && DEBUG
+ (void)resetClassDependencies;
#endif

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
