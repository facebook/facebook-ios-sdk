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

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKLoginCompletion+Internal.h"

 #if SWIFT_PACKAGE
@import FBSDKCoreKit;
 #else
  #import <FBSDKCoreKit/FBSDKCoreKit.h>
 #endif

 #import "FBSDKLoginConstants.h"
 #import "FBSDKLoginError.h"
 #import "FBSDKLoginManager+Internal.h"
 #import "FBSDKLoginUtility.h"
 #import "FBSDKPermission.h"
 #import "FBSDKProfileFactory.h"

@implementation FBSDKLoginCompletionParameters

- (instancetype)init
{
  return [super init];
}

- (instancetype)initWithError:(NSError *)error
{
  if ((self = [self init]) != nil) {
    self.error = error;
  }
  return self;
}

@end

 #pragma mark - Completers

@implementation FBSDKLoginURLCompleter
{
  FBSDKLoginCompletionParameters *_parameters;
  id<NSObject> _observer;
  BOOL _performExplicitFallback;
}

static id<FBSDKProfileProviding> _profileFactory;
static NSDateFormatter *_dateFormatter;

+ (void)initialize
{
  if (self == [FBSDKLoginURLCompleter class]) {
    _profileFactory = [FBSDKProfileFactory new];
  }
}

- (instancetype)initWithURLParameters:(NSDictionary *)parameters
                                appID:(NSString *)appID
{
  if ((self = [super init]) != nil) {
    _parameters = [FBSDKLoginCompletionParameters new];

    BOOL hasNonEmptyNonceString = ((NSString *)[FBSDKTypeUtility dictionary:parameters objectForKey:@"nonce" ofType:NSString.class]).length > 0;
    BOOL hasNonEmptyIdTokenString = ((NSString *)[FBSDKTypeUtility dictionary:parameters objectForKey:@"id_token" ofType:NSString.class]).length > 0;
    BOOL hasNonEmptyAccessTokenString = ((NSString *)[FBSDKTypeUtility dictionary:parameters objectForKey:@"access_token" ofType:NSString.class]).length > 0;

    // Nonce and id token are mutually exclusive parameters
    BOOL hasBothNonceAndIdToken = hasNonEmptyNonceString && hasNonEmptyIdTokenString;
    BOOL hasEitherNonceOrIdToken = hasNonEmptyNonceString || hasNonEmptyIdTokenString;

    if (hasNonEmptyAccessTokenString || (hasEitherNonceOrIdToken && !hasBothNonceAndIdToken)) {
      [self setParametersWithDictionary:parameters appID:appID];
    } else if ([FBSDKTypeUtility dictionary:parameters objectForKey:@"error" ofType:NSString.class] || [FBSDKTypeUtility dictionary:parameters objectForKey:@"error_message" ofType:NSString.class]) {
      [self setErrorWithDictionary:parameters];
    } else if (hasBothNonceAndIdToken) {
      // If a nonce is present in the parameter we assume that
      // user logged in by app switching.
      // Currently OIDC is not supported for app switching. We
      // will treat the login attempt as invalid if an ID token
      // if returned together with nonce.
      _parameters.error = [FBSDKError errorWithCode:FBSDKLoginErrorUnknown message:@"Invalid server response. Please try to login again"];
    }
  }
  return self;
}

- (void)completeLoginWithHandler:(FBSDKLoginCompletionParametersBlock)handler
{
  [self completeLoginWithHandler:handler nonce:nil];
}

/// Performs the work needed to populate the login completion parameters before they
/// are used to determine login success, failure or cancellation.
- (void)completeLoginWithHandler:(FBSDKLoginCompletionParametersBlock)handler
                           nonce:(nullable NSString *)nonce
{
  // If there is a nonceString then it means we logged in from the app.
  if (_parameters.nonceString) {
    [self exchangeNonceForTokenWithHandler:handler];
  } else if (_parameters.authenticationTokenString && !nonce) {
    // If there is no nonce then somehow an auth token string was provided
    // but the call did not originate from the sdk. This is not a valid state
    _parameters.error = [FBSDKError errorWithCode:FBSDKLoginErrorUnknown message:@"Please try to login again"];
    handler(_parameters);
  } else if (_parameters.authenticationTokenString && nonce) {
    [self fetchAndSetPropertiesForParameters:_parameters nonce:nonce handler:handler];
  } else {
    handler(_parameters);
  }
}

/// Sets authenticationToken and profile onto the provided parameters and calls the provided completion handler
- (void)fetchAndSetPropertiesForParameters:(nonnull FBSDKLoginCompletionParameters *)parameters
                                     nonce:(nonnull NSString *)nonce
                                   handler:(FBSDKLoginCompletionParametersBlock)handler
{
  FBSDKAuthenticationTokenBlock completion = ^(FBSDKAuthenticationToken *token) {
    if (token) {
      parameters.authenticationToken = token;
      parameters.profile = [FBSDKLoginURLCompleter profileWithClaims:token.claims];
    } else {
      parameters.error = [FBSDKError errorWithCode:FBSDKLoginErrorInvalidIDToken message:@"Invalid ID token from login response."];
    }
    handler(parameters);
  };
  [[FBSDKAuthenticationTokenFactory new] createTokenFromTokenString:_parameters.authenticationTokenString
                                                              nonce:nonce
                                                        graphDomain:parameters.graphDomain
                                                         completion:completion];
}

- (void)setParametersWithDictionary:(NSDictionary *)parameters appID:(NSString *)appID
{
  NSString *grantedPermissionsString = [FBSDKTypeUtility dictionary:parameters objectForKey:@"granted_scopes" ofType:NSString.class];
  NSString *declinedPermissionsString = [FBSDKTypeUtility dictionary:parameters objectForKey:@"denied_scopes" ofType:NSString.class];
  NSString *signedRequest = [FBSDKTypeUtility dictionary:parameters objectForKey:@"signed_request" ofType:NSString.class];
  NSString *userID = [FBSDKTypeUtility dictionary:parameters objectForKey:@"user_id" ofType:NSString.class];
  NSString *domain = [FBSDKTypeUtility dictionary:parameters objectForKey:@"graph_domain" ofType:NSString.class];

  _parameters.accessTokenString = [FBSDKTypeUtility dictionary:parameters objectForKey:@"access_token" ofType:NSString.class];
  _parameters.nonceString = [FBSDKTypeUtility dictionary:parameters objectForKey:@"nonce" ofType:NSString.class];
  _parameters.authenticationTokenString = [FBSDKTypeUtility dictionary:parameters objectForKey:@"id_token" ofType:NSString.class];

  // check the string length so that we assign an empty set rather than a set with an empty string
  _parameters.permissions = (grantedPermissionsString.length > 0)
  ? [FBSDKPermission permissionsFromRawPermissions:[NSSet setWithArray:[grantedPermissionsString componentsSeparatedByString:@","]]]
  : NSSet.set;
  _parameters.declinedPermissions = (declinedPermissionsString.length > 0)
  ? [FBSDKPermission permissionsFromRawPermissions:[NSSet setWithArray:[declinedPermissionsString componentsSeparatedByString:@","]]]
  : NSSet.set;

  _parameters.expiredPermissions = NSSet.set;

  _parameters.appID = appID;

  if (userID.length == 0 && signedRequest.length > 0) {
    _parameters.userID = [FBSDKLoginUtility userIDFromSignedRequest:signedRequest];
  } else {
    _parameters.userID = userID;
  }

  if (domain.length > 0) {
    _parameters.graphDomain = domain;
  }

  _parameters.expirationDate = [FBSDKLoginURLCompleter expirationDateFromParameters:parameters];
  _parameters.dataAccessExpirationDate = [FBSDKLoginURLCompleter dataAccessExpirationDateFromParameters:parameters];
  _parameters.challenge = [FBSDKLoginURLCompleter challengeFromParameters:parameters];
}

- (void)setErrorWithDictionary:(NSDictionary *)parameters
{
  NSString *legacyErrorReason = [FBSDKTypeUtility dictionary:parameters objectForKey:@"error" ofType:NSString.class];

  if ([legacyErrorReason isEqualToString:@"service_disabled_use_browser"]
      || [legacyErrorReason isEqualToString:@"service_disabled"]) {
    _performExplicitFallback = YES;
  }

  // if error is nil, then this should be processed as a cancellation unless
  // _performExplicitFallback is set to YES and the log in behavior is Native.
  _parameters.error = [NSError fbErrorFromReturnURLParameters:parameters];
}

- (void)exchangeNonceForTokenWithHandler:(FBSDKLoginCompletionParametersBlock)handler
{
  id<FBSDKGraphRequestConnectionProviding> provider = [FBSDKGraphRequestConnectionFactory new];
  [self exchangeNonceForTokenWithGraphRequestConnectionProvider:provider handler:handler];
}

- (void)exchangeNonceForTokenWithGraphRequestConnectionProvider:(nonnull id<FBSDKGraphRequestConnectionProviding>)connectionProvider
                                                        handler:(nonnull FBSDKLoginCompletionParametersBlock)handler
{
  if (!handler) {
    return;
  }

  NSString *nonce = _parameters.nonceString ?: @"";
  NSString *appID = _parameters.appID ?: @"";

  if (nonce.length == 0 || appID.length == 0) {
    _parameters.error = [FBSDKError errorWithCode:FBSDKErrorInvalidArgument message:@"Missing required parameters to exchange nonce for access token."];
    handler(_parameters);
    return;
  }

  FBSDKGraphRequest *tokenRequest = [[FBSDKGraphRequest alloc]
                                     initWithGraphPath:@"oauth/access_token"
                                     parameters:@{ @"grant_type" : @"fb_exchange_nonce",
                                                   @"fb_exchange_nonce" : nonce,
                                                   @"client_id" : appID,
                                                   @"fields" : @"" }
                                     flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError
                                     | FBSDKGraphRequestFlagDisableErrorRecovery];
  __block FBSDKLoginCompletionParameters *parameters = _parameters;
  FBSDKGraphRequestConnection *connection = (FBSDKGraphRequestConnection *)[connectionProvider createGraphRequestConnection];
  [connection addRequest:tokenRequest completionHandler:^(FBSDKGraphRequestConnection *requestConnection,
                                                          id result,
                                                          NSError *graphRequestError) {
                                                            if (!graphRequestError) {
                                                              parameters.accessTokenString = [FBSDKTypeUtility dictionary:result objectForKey:@"access_token" ofType:NSString.class];
                                                              parameters.expirationDate = [FBSDKLoginURLCompleter expirationDateFromParameters:result];
                                                              parameters.dataAccessExpirationDate = [FBSDKLoginURLCompleter dataAccessExpirationDateFromParameters:result];
                                                            } else {
                                                              parameters.error = graphRequestError;
                                                            }

                                                            handler(parameters);
                                                          }];

  [connection start];
}

+ (nullable FBSDKProfile *)profileWithClaims:(FBSDKAuthenticationTokenClaims *)claims
{
  if (claims.sub.length == 0) {
    return nil;
  }

  NSURL *imageURL;
  if (claims.picture) {
    imageURL = [NSURL URLWithString:claims.picture];
  }

  NSDate *birthday;
  if (claims.userBirthday) {
    [FBSDKLoginURLCompleter.dateFormatter setDateFormat:@"MM/dd/yyyy"];
    birthday = [FBSDKLoginURLCompleter.dateFormatter dateFromString:claims.userBirthday];
  }

  return [_profileFactory createProfileWithUserID:claims.sub
                                        firstName:nil
                                       middleName:nil
                                         lastName:nil
                                             name:claims.name
                                          linkURL:nil
                                      refreshDate:nil
                                         imageURL:imageURL
                                            email:claims.email
                                        friendIDs:claims.userFriends
                                         birthday:birthday
                                         ageRange:[FBSDKUserAgeRange ageRangeFromDictionary:claims.userAgeRange]
                                        isLimited:YES];
}

+ (NSDate *)expirationDateFromParameters:(NSDictionary *)parameters
{
  NSString *expiresString = [FBSDKTypeUtility dictionary:parameters objectForKey:@"expires" ofType:NSString.class];
  NSString *expiresAtString = [FBSDKTypeUtility dictionary:parameters objectForKey:@"expires_at" ofType:NSString.class];
  NSString *expiresInString = [FBSDKTypeUtility dictionary:parameters objectForKey:@"expires_in" ofType:NSString.class];
  NSString *expirationDateString = expiresString ?: expiresAtString;

  if (expirationDateString.doubleValue > 0) {
    return [NSDate dateWithTimeIntervalSince1970:expirationDateString.doubleValue];
  } else if (expiresInString.integerValue > 0) {
    return [NSDate dateWithTimeIntervalSinceNow:expiresInString.integerValue];
  } else {
    return NSDate.distantFuture;
  }
}

+ (NSDate *)dataAccessExpirationDateFromParameters:(NSDictionary *)parameters
{
  NSString *dataAccessExpirationDateString = [FBSDKTypeUtility dictionary:parameters objectForKey:@"data_access_expiration_time" ofType:NSString.class];
  if (dataAccessExpirationDateString.integerValue > 0) {
    return [NSDate dateWithTimeIntervalSince1970:dataAccessExpirationDateString.integerValue];
  } else {
    return NSDate.distantFuture;
  }
}

+ (NSString *)challengeFromParameters:(NSDictionary *)parameters
{
  NSString *stateString = [FBSDKTypeUtility dictionary:parameters objectForKey:@"state" ofType:NSString.class];
  if (stateString.length > 0) {
    NSError *error = nil;
    NSDictionary<id, id> *state = [FBSDKBasicUtility objectForJSONString:stateString error:&error];

    if (!error) {
      NSString *challenge = [FBSDKTypeUtility dictionary:state objectForKey:@"challenge" ofType:NSString.class];
      if (challenge.length > 0) {
        return [FBSDKUtility URLDecode:challenge];
      }
    }
  }
  return nil;
}

+ (NSDateFormatter *)dateFormatter
{
  if (!_dateFormatter) {
    _dateFormatter = NSDateFormatter.new;
  }
  return _dateFormatter;
}

// MARK: Test Helpers

 #if DEBUG
  #if FBSDKTEST

+ (id<FBSDKProfileProviding>)profileFactory
{
  return _profileFactory;
}

+ (void)setProfileFactory:(id<FBSDKProfileProviding>)factory
{
  _profileFactory = factory;
}

- (FBSDKLoginCompletionParameters *)parameters
{
  return _parameters;
}

+ (void)reset
{
  _profileFactory = [FBSDKProfileFactory new];
}

  #endif
 #endif

@end

#endif
