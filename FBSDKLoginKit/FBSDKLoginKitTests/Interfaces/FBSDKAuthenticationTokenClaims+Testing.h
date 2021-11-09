/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAuthenticationTokenClaims (Testing)

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
                        userAgeRange:(nullable NSDictionary<NSString *, id> *)userAgeRange
                        userHometown:(nullable NSDictionary<NSString *, id> *)userHometown
                        userLocation:(nullable NSDictionary<NSString *, id> *)userLocation
                          userGender:(nullable NSString *)userGender
                            userLink:(nullable NSString *)userLink;

@end

NS_ASSUME_NONNULL_END
