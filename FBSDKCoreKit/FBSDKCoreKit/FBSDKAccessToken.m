/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAccessToken+Internal.h"

#import <FBSDKCoreKit/FBSDKErrorCreating.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKConstants.h"
#import "FBSDKGraphRequestConnecting.h"
#import "FBSDKGraphRequestConnectionFactory.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKMath.h"

NSNotificationName const FBSDKAccessTokenDidChangeNotification = @"com.facebook.sdk.FBSDKAccessTokenData.FBSDKAccessTokenDidChangeNotification";

NSString *const FBSDKAccessTokenDidChangeUserIDKey = @"FBSDKAccessTokenDidChangeUserIDKey";
NSString *const FBSDKAccessTokenChangeNewKey = @"FBSDKAccessToken";
NSString *const FBSDKAccessTokenChangeOldKey = @"FBSDKAccessTokenOld";
NSString *const FBSDKAccessTokenDidExpireKey = @"FBSDKAccessTokenDidExpireKey";

static FBSDKAccessToken *g_currentAccessToken;
static id<FBSDKTokenCaching> g_tokenCache;
static id<FBSDKGraphRequestConnectionFactory> g_graphRequestConnectionFactory;
static Class<FBSDKGraphRequestPiggybackManaging> g_graphRequestPiggybackManager;
static id<FBSDKErrorCreating> g_errorFactory;

#define FBSDK_ACCESSTOKEN_TOKENSTRING_KEY @"tokenString"
#define FBSDK_ACCESSTOKEN_PERMISSIONS_KEY @"permissions"
#define FBSDK_ACCESSTOKEN_DECLINEDPERMISSIONS_KEY @"declinedPermissions"
#define FBSDK_ACCESSTOKEN_EXPIREDPERMISSIONS_KEY @"expiredPermissions"
#define FBSDK_ACCESSTOKEN_APPID_KEY @"appID"
#define FBSDK_ACCESSTOKEN_USERID_KEY @"userID"
#define FBSDK_ACCESSTOKEN_REFRESHDATE_KEY @"refreshDate"
#define FBSDK_ACCESSTOKEN_EXPIRATIONDATE_KEY @"expirationDate"
#define FBSDK_ACCESSTOKEN_DATA_EXPIRATIONDATE_KEY @"dataAccessExpirationDate"
#define FBSDK_ACCESSTOKEN_GRAPH_DOMAIN_KEY @"graphDomain"

@implementation FBSDKAccessToken

- (instancetype)initWithTokenString:(NSString *)tokenString
                        permissions:(NSArray<NSString *> *)permissions
                declinedPermissions:(NSArray<NSString *> *)declinedPermissions
                 expiredPermissions:(NSArray<NSString *> *)expiredPermissions
                              appID:(NSString *)appID
                             userID:(NSString *)userID
                     expirationDate:(NSDate *)expirationDate
                        refreshDate:(NSDate *)refreshDate
           dataAccessExpirationDate:(NSDate *)dataAccessExpirationDate
{
  if ((self = [super init])) {
    _tokenString = [tokenString copy];
    _permissions = [NSSet setWithArray:permissions];
    _declinedPermissions = [NSSet setWithArray:declinedPermissions];
    _expiredPermissions = [NSSet setWithArray:expiredPermissions];
    _appID = [appID copy];
    _userID = [userID copy];
    _expirationDate = [expirationDate copy] ?: NSDate.distantFuture;
    _refreshDate = [refreshDate copy] ?: [NSDate date];
    _dataAccessExpirationDate = [dataAccessExpirationDate copy] ?: NSDate.distantFuture;
  }
  return self;
}

- (BOOL)hasGranted:(NSString *)permission
{
  return [self.permissions containsObject:permission];
}

- (BOOL)isDataAccessExpired
{
  return [self.dataAccessExpirationDate compare:NSDate.date] == NSOrderedAscending;
}

- (BOOL)isExpired
{
  return [self.expirationDate compare:NSDate.date] == NSOrderedAscending;
}

+ (id<FBSDKTokenCaching>)tokenCache
{
  return g_tokenCache;
}

+ (void)setTokenCache:(id<FBSDKTokenCaching>)cache
{
  if (g_tokenCache != cache) {
    g_tokenCache = cache;
  }
}

+ (void)resetTokenCache
{
  FBSDKAccessToken.tokenCache = nil;
}

+ (FBSDKAccessToken *)currentAccessToken
{
  return g_currentAccessToken;
}

+ (NSString *)tokenString
{
  return FBSDKAccessToken.currentAccessToken.tokenString;
}

+ (void)setCurrentAccessToken:(FBSDKAccessToken *)token
{
  [FBSDKAccessToken setCurrentAccessToken:token shouldDispatchNotif:YES];
}

+ (void)setCurrentAccessToken:(nullable FBSDKAccessToken *)token
          shouldDispatchNotif:(BOOL)shouldDispatchNotif
{
  if (token != g_currentAccessToken) {
    NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary dictionary];
    [FBSDKTypeUtility dictionary:userInfo setObject:token forKey:FBSDKAccessTokenChangeNewKey];
    [FBSDKTypeUtility dictionary:userInfo setObject:g_currentAccessToken forKey:FBSDKAccessTokenChangeOldKey];
    // We set this flag also when the current Access Token was not valid, since there might be legacy code relying on it
    if (![g_currentAccessToken.userID isEqualToString:token.userID] || !self.isCurrentAccessTokenActive) {
      userInfo[FBSDKAccessTokenDidChangeUserIDKey] = @YES;
    }

    g_currentAccessToken = token;

    // Only need to keep current session in web view for the case when token is current
    // When token is abandoned cookies must to be cleaned up immediately
    if (token == nil) {
      [FBSDKInternalUtility.sharedUtility deleteFacebookCookies];
    }

    self.tokenCache.accessToken = token;
    if (shouldDispatchNotif) {
      [NSNotificationCenter.defaultCenter postNotificationName:FBSDKAccessTokenDidChangeNotification
                                                        object:self.class
                                                      userInfo:userInfo];
    }
  }
}

+ (BOOL)isCurrentAccessTokenActive
{
  FBSDKAccessToken *currentAccessToken = [self currentAccessToken];
  return currentAccessToken != nil && !currentAccessToken.isExpired;
}

+ (void)refreshCurrentAccessTokenWithCompletion:(nullable FBSDKGraphRequestCompletion)completion
{
  if (FBSDKAccessToken.currentAccessToken) {
    id<FBSDKGraphRequestConnecting> connection = [FBSDKAccessToken.graphRequestConnectionFactory createGraphRequestConnection];
    if (connection) {
      [self.graphRequestPiggybackManager addRefreshPiggyback:connection permissionHandler:completion];
      [connection start];
    } else {
    #if DEBUG
      static NSString *const reason = @"As of v9.0, you must initialize the SDK prior to calling any methods or setting any properties. "
      "You can do this by calling `FBSDKApplicationDelegate`'s `application:didFinishLaunchingWithOptions:` method. "
      "Learn more: https://developers.facebook.com/docs/ios/getting-started"
      "If no `UIApplication` is available you can use `FBSDKApplicationDelegate`'s `initializeSDK` method.";
      @throw [NSException exceptionWithName:@"InvalidOperationException" reason:reason userInfo:nil];
    #endif
    }
  } else if (completion) {
    NSError *error = [self.errorFactory errorWithCode:FBSDKErrorAccessTokenRequired
                                             userInfo:nil
                                              message:@"No current access token to refresh"
                                      underlyingError:nil];
    completion(nil, nil, error);
  }
}

+ (nullable id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
{
  return g_graphRequestConnectionFactory;
}

+ (void)setGraphRequestConnectionFactory:(nullable id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
{
  if (g_graphRequestConnectionFactory != graphRequestConnectionFactory) {
    g_graphRequestConnectionFactory = graphRequestConnectionFactory;
  }
}

+ (nullable Class<FBSDKGraphRequestPiggybackManaging>)graphRequestPiggybackManager
{
  return g_graphRequestPiggybackManager;
}

+ (void)setGraphRequestPiggybackManager:(nullable Class<FBSDKGraphRequestPiggybackManaging>)graphRequestPiggybackManager
{
  g_graphRequestPiggybackManager = graphRequestPiggybackManager;
}

+ (nullable id<FBSDKErrorCreating>)errorFactory
{
  return g_errorFactory;
}

+ (void)setErrorFactory:(nullable id<FBSDKErrorCreating>)errorFactory
{
  g_errorFactory = errorFactory;
}

+ (void)configureWithTokenCache:(id<FBSDKTokenCaching>)tokenCache
  graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
   graphRequestPiggybackManager:(Class<FBSDKGraphRequestPiggybackManaging>)graphRequestPiggybackManager
                   errorFactory:(id<FBSDKErrorCreating>)errorFactory
{
  self.tokenCache = tokenCache;
  self.graphRequestConnectionFactory = graphRequestConnectionFactory;
  self.graphRequestPiggybackManager = graphRequestPiggybackManager;
  self.errorFactory = errorFactory;
}

#pragma mark - Equality

- (NSUInteger)hash
{
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  NSUInteger subhashes[] = {
    self.tokenString.hash,
    self.permissions.hash,
    self.declinedPermissions.hash,
    self.expiredPermissions.hash,
    self.appID.hash,
    self.userID.hash,
    self.refreshDate.hash,
    self.expirationDate.hash,
    self.dataAccessExpirationDate.hash,
  };
  #pragma clang diagnostic pop

  return [FBSDKMath hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:FBSDKAccessToken.class]) {
    return NO;
  }
  return [self isEqualToAccessToken:(FBSDKAccessToken *)object];
}

- (BOOL)isEqualToAccessToken:(FBSDKAccessToken *)token
{
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  return (token
    && [FBSDKInternalUtility.sharedUtility object:self.tokenString isEqualToObject:token.tokenString]
    && [FBSDKInternalUtility.sharedUtility object:self.permissions isEqualToObject:token.permissions]
    && [FBSDKInternalUtility.sharedUtility object:self.declinedPermissions isEqualToObject:token.declinedPermissions]
    && [FBSDKInternalUtility.sharedUtility object:self.expiredPermissions isEqualToObject:token.expiredPermissions]
    && [FBSDKInternalUtility.sharedUtility object:self.appID isEqualToObject:token.appID]
    && [FBSDKInternalUtility.sharedUtility object:self.userID isEqualToObject:token.userID]
    && [FBSDKInternalUtility.sharedUtility object:self.refreshDate isEqualToObject:token.refreshDate]
    && [FBSDKInternalUtility.sharedUtility object:self.expirationDate isEqualToObject:token.expirationDate]
    && [FBSDKInternalUtility.sharedUtility object:self.dataAccessExpirationDate isEqualToObject:token.dataAccessExpirationDate]);
  #pragma clang diagnostic pop
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  // we're immutable.
  return self;
}

#pragma mark NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  NSString *appID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_ACCESSTOKEN_APPID_KEY];
  NSSet<NSString *> *declinedPermissions = [decoder decodeObjectOfClass:NSSet.class forKey:FBSDK_ACCESSTOKEN_DECLINEDPERMISSIONS_KEY];
  NSSet<NSString *> *expiredPermissions = [decoder decodeObjectOfClass:NSSet.class forKey:FBSDK_ACCESSTOKEN_EXPIREDPERMISSIONS_KEY];
  NSSet<NSString *> *permissions = [decoder decodeObjectOfClass:NSSet.class forKey:FBSDK_ACCESSTOKEN_PERMISSIONS_KEY];
  NSString *tokenString = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_ACCESSTOKEN_TOKENSTRING_KEY];
  NSString *userID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_ACCESSTOKEN_USERID_KEY];
  NSDate *refreshDate = [decoder decodeObjectOfClass:NSDate.class forKey:FBSDK_ACCESSTOKEN_REFRESHDATE_KEY];
  NSDate *expirationDate = [decoder decodeObjectOfClass:NSDate.class forKey:FBSDK_ACCESSTOKEN_EXPIRATIONDATE_KEY];
  NSDate *dataAccessExpirationDate = [decoder decodeObjectOfClass:NSDate.class forKey:FBSDK_ACCESSTOKEN_DATA_EXPIRATIONDATE_KEY];

  return
  [self
   initWithTokenString:tokenString
   permissions:permissions.allObjects
   declinedPermissions:declinedPermissions.allObjects
   expiredPermissions:expiredPermissions.allObjects
   appID:appID
   userID:userID
   expirationDate:expirationDate
   refreshDate:refreshDate
   dataAccessExpirationDate:dataAccessExpirationDate];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.appID forKey:FBSDK_ACCESSTOKEN_APPID_KEY];
  [encoder encodeObject:self.declinedPermissions forKey:FBSDK_ACCESSTOKEN_DECLINEDPERMISSIONS_KEY];
  [encoder encodeObject:self.expiredPermissions forKey:FBSDK_ACCESSTOKEN_EXPIREDPERMISSIONS_KEY];
  [encoder encodeObject:self.permissions forKey:FBSDK_ACCESSTOKEN_PERMISSIONS_KEY];
  [encoder encodeObject:self.tokenString forKey:FBSDK_ACCESSTOKEN_TOKENSTRING_KEY];
  [encoder encodeObject:self.userID forKey:FBSDK_ACCESSTOKEN_USERID_KEY];
  [encoder encodeObject:self.expirationDate forKey:FBSDK_ACCESSTOKEN_EXPIRATIONDATE_KEY];
  [encoder encodeObject:self.refreshDate forKey:FBSDK_ACCESSTOKEN_REFRESHDATE_KEY];
  [encoder encodeObject:self.dataAccessExpirationDate forKey:FBSDK_ACCESSTOKEN_DATA_EXPIRATIONDATE_KEY];
}

#pragma mark - Testability

#if DEBUG && FBTEST

+ (void)resetClassDependencies
{
  self.tokenCache = nil;
  self.graphRequestConnectionFactory = nil;
  self.graphRequestPiggybackManager = nil;
  self.errorFactory = nil;
}

+ (void)resetCurrentAccessTokenCache
{
  g_currentAccessToken = nil;
}

#endif

@end
