/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKAccessTokenProviding.h>
#import <FBSDKCoreKit/FBSDKTokenStringProviding.h>
#import <FBSDKCoreKit/FBSDKGraphRequestConnection.h>
#import <FBSDKCoreKit/FBSDKTokenCaching.h>

@protocol FBSDKGraphRequestConnectionFactory;
@protocol FBSDKGraphRequestPiggybackManaging;
@protocol FBSDKErrorCreating;

NS_ASSUME_NONNULL_BEGIN

/**
 Notification indicating that the `currentAccessToken` has changed.

 the userInfo dictionary of the notification will contain keys
 `FBSDKAccessTokenChangeOldKey` and
 `FBSDKAccessTokenChangeNewKey`.
 */
FOUNDATION_EXPORT NSNotificationName const FBSDKAccessTokenDidChangeNotification
NS_SWIFT_NAME(AccessTokenDidChange);

/**
 A key in the notification's userInfo that will be set
 if and only if the user ID changed between the old and new tokens.

 Token refreshes can occur automatically with the SDK
 which do not change the user. If you're only interested in user
 changes (such as logging out), you should check for the existence
 of this key. The value is a NSNumber with a boolValue.

 On a fresh start of the app where the SDK reads in the cached value
 of an access token, this key will also exist since the access token
 is moving from a null state (no user) to a non-null state (user).
 */
FOUNDATION_EXPORT NSString *const FBSDKAccessTokenDidChangeUserIDKey
NS_SWIFT_NAME(AccessTokenDidChangeUserIDKey);

/*
  key in notification's userInfo object for getting the old token.

 If there was no old token, the key will not be present.
 */
FOUNDATION_EXPORT NSString *const FBSDKAccessTokenChangeOldKey
NS_SWIFT_NAME(AccessTokenChangeOldKey);

/*
  key in notification's userInfo object for getting the new token.

 If there is no new token, the key will not be present.
 */
FOUNDATION_EXPORT NSString *const FBSDKAccessTokenChangeNewKey
NS_SWIFT_NAME(AccessTokenChangeNewKey);

/*
 A key in the notification's userInfo that will be set
 if and only if the token has expired.
 */
FOUNDATION_EXPORT NSString *const FBSDKAccessTokenDidExpireKey
NS_SWIFT_NAME(AccessTokenDidExpireKey);

/// Represents an immutable access token for using Facebook services.
NS_SWIFT_NAME(AccessToken)
@interface FBSDKAccessToken : NSObject <NSCopying, NSObject, NSSecureCoding, FBSDKAccessTokenProviding, FBSDKTokenStringProviding>

/**
 The "global" access token that represents the currently logged in user.

 The `currentAccessToken` is a convenient representation of the token of the
 current user and is used by other SDK components (like `FBSDKLoginManager`).
 */
@property (class, nullable, nonatomic, copy) FBSDKAccessToken *currentAccessToken NS_SWIFT_NAME(current);

/// Returns YES if currentAccessToken is not nil AND currentAccessToken is not expired
@property (class, nonatomic, readonly, getter = isCurrentAccessTokenActive, assign) BOOL currentAccessTokenIsActive;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@property (class, nullable, nonatomic, copy) id<FBSDKTokenCaching> tokenCache;

/// Returns the app ID.
@property (nonatomic, readonly, copy) NSString *appID;

/// Returns the expiration date for data access
@property (nonatomic, readonly, copy) NSDate *dataAccessExpirationDate;

/// Returns the known declined permissions.
@property (nonatomic, readonly, copy) NSSet<NSString *> *declinedPermissions
  NS_REFINED_FOR_SWIFT;

/// Returns the known declined permissions.
@property (nonatomic, readonly, copy) NSSet<NSString *> *expiredPermissions
  NS_REFINED_FOR_SWIFT;

/// Returns the expiration date.
@property (nonatomic, readonly, copy) NSDate *expirationDate;

/// Returns the known granted permissions.
@property (nonatomic, readonly, copy) NSSet<NSString *> *permissions
  NS_REFINED_FOR_SWIFT;

/// Returns the date the token was last refreshed.
@property (nonatomic, readonly, copy) NSDate *refreshDate;

/// Returns the opaque token string.
@property (nonatomic, readonly, copy) NSString *tokenString;

/// Returns the user ID.
@property (nonatomic, readonly, copy) NSString *userID;

/// Returns whether the access token is expired by checking its expirationDate property
@property (nonatomic, readonly, getter = isExpired, assign) BOOL expired;

/// Returns whether user data access is still active for the given access token
@property (nonatomic, readonly, getter = isDataAccessExpired, assign) BOOL dataAccessExpired;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Initializes a new instance.
 @param tokenString the opaque token string.
 @param permissions the granted permissions. Note this is converted to NSSet and is only
 an NSArray for the convenience of literal syntax.
 @param declinedPermissions the declined permissions. Note this is converted to NSSet and is only
 an NSArray for the convenience of literal syntax.
 @param expiredPermissions the expired permissions. Note this is converted to NSSet and is only
 an NSArray for the convenience of literal syntax.
 @param appID the app ID.
 @param userID the user ID.
 @param expirationDate the optional expiration date (defaults to distantFuture).
 @param refreshDate the optional date the token was last refreshed (defaults to today).
 @param dataAccessExpirationDate the date which data access will expire for the given user
 (defaults to distantFuture).

 This initializer should only be used for advanced apps that
 manage tokens explicitly. Typical login flows only need to use `FBSDKLoginManager`
 along with `+currentAccessToken`.
 */
- (instancetype)initWithTokenString:(NSString *)tokenString
                        permissions:(NSArray<NSString *> *)permissions
                declinedPermissions:(NSArray<NSString *> *)declinedPermissions
                 expiredPermissions:(NSArray<NSString *> *)expiredPermissions
                              appID:(NSString *)appID
                             userID:(NSString *)userID
                     expirationDate:(nullable NSDate *)expirationDate
                        refreshDate:(nullable NSDate *)refreshDate
           dataAccessExpirationDate:(nullable NSDate *)dataAccessExpirationDate
  NS_DESIGNATED_INITIALIZER;

/**
 Convenience getter to determine if a permission has been granted
 @param permission  The permission to check.
 */
// UNCRUSTIFY_FORMAT_OFF
- (BOOL)hasGranted:(NSString *)permission
NS_SWIFT_NAME(hasGranted(permission:));
// UNCRUSTIFY_FORMAT_ON

/**
 Compares the receiver to another FBSDKAccessToken
 @param token The other token
 @return YES if the receiver's values are equal to the other token's values; otherwise NO
 */
- (BOOL)isEqualToAccessToken:(FBSDKAccessToken *)token;

/**
 Refresh the current access token's permission state and extend the token's expiration date,
  if possible.
 @param completion an optional callback handler that can surface any errors related to permission refreshing.

 On a successful refresh, the currentAccessToken will be updated so you typically only need to
  observe the `FBSDKAccessTokenDidChangeNotification` notification.

 If a token is already expired, it cannot be refreshed.
 */
+ (void)refreshCurrentAccessTokenWithCompletion:(nullable FBSDKGraphRequestCompletion)completion;

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
+ (void)configureWithTokenCache:(id<FBSDKTokenCaching>)tokenCache
  graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
   graphRequestPiggybackManager:(id<FBSDKGraphRequestPiggybackManaging>)graphRequestPiggybackManager
                   errorFactory:(id<FBSDKErrorCreating>)errorFactory
NS_SWIFT_NAME(configure(tokenCache:graphRequestConnectionFactory:graphRequestPiggybackManager:errorFactory:));


@end

NS_ASSUME_NONNULL_END
