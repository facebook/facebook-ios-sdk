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

@interface FBSDKAuthenticationToken (ClaimsProviding)

- (FBSDKAuthenticationTokenClaims *)claims;

@end

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

- (instancetype)initWithURLParameters:(NSDictionary *)parameters
                                appID:(NSString *)appID
{
  if ((self = [super init]) != nil) {
    _parameters = [[FBSDKLoginCompletionParameters alloc] init];

    BOOL hasNonEmptyNonceString = [parameters[@"nonce"] length] > 0;
    BOOL hasNonEmptyIdTokenString = [parameters[@"id_token"] length] > 0;

    // TODO: T81282385 - Error if nonce and ID Token
    // Nonce and id token are mutually exclusive parameters
    // BOOL isInvalid = (hasNonEmptyNonceString && hasNonEmptyIdTokenString);

    if ([parameters[@"access_token"] length] > 0
        || hasNonEmptyNonceString
        || hasNonEmptyIdTokenString) {
      [self setParametersWithDictionary:parameters appID:appID];
    } else {
      [self setErrorWithDictionary:parameters];
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
  [[FBSDKAuthenticationTokenFactory new] createTokenFromTokenString:_parameters.authenticationTokenString nonce:nonce completion:completion];
}

- (void)setParametersWithDictionary:(NSDictionary *)parameters appID:(NSString *)appID
{
  NSString *grantedPermissionsString = parameters[@"granted_scopes"];
  NSString *declinedPermissionsString = parameters[@"denied_scopes"];

  NSString *signedRequest = parameters[@"signed_request"];
  NSString *userID = parameters[@"user_id"];

  _parameters.accessTokenString = parameters[@"access_token"];
  _parameters.nonceString = parameters[@"nonce"];
  _parameters.authenticationTokenString = parameters[@"id_token"];

  // check the string length so that we assign an empty set rather than a set with an empty string
  _parameters.permissions = (grantedPermissionsString.length > 0)
  ? [NSSet setWithArray:[grantedPermissionsString componentsSeparatedByString:@","]]
  : [NSSet set];
  _parameters.declinedPermissions = (declinedPermissionsString.length > 0)
  ? [NSSet setWithArray:[declinedPermissionsString componentsSeparatedByString:@","]]
  : [NSSet set];

  _parameters.expiredPermissions = [NSSet set];

  _parameters.appID = appID;

  if (userID.length == 0 && signedRequest.length > 0) {
    _parameters.userID = [FBSDKLoginUtility userIDFromSignedRequest:signedRequest];
  } else {
    _parameters.userID = userID;
  }

  NSString *expirationDateString = parameters[@"expires"] ?: parameters[@"expires_at"];
  NSDate *expirationDate = [NSDate distantFuture];
  if (expirationDateString && expirationDateString.doubleValue > 0) {
    expirationDate = [NSDate dateWithTimeIntervalSince1970:expirationDateString.doubleValue];
  } else if (parameters[@"expires_in"] && [parameters[@"expires_in"] integerValue] > 0) {
    expirationDate = [NSDate dateWithTimeIntervalSinceNow:[parameters[@"expires_in"] integerValue]];
  }
  _parameters.expirationDate = expirationDate;

  NSDate *dataAccessExpirationDate = [NSDate distantFuture];
  if (parameters[@"data_access_expiration_time"] && [parameters[@"data_access_expiration_time"] integerValue] > 0) {
    dataAccessExpirationDate = [NSDate dateWithTimeIntervalSince1970:[parameters[@"data_access_expiration_time"] integerValue]];
  }
  _parameters.dataAccessExpirationDate = dataAccessExpirationDate;

  NSError *error = nil;
  NSDictionary<id, id> *state = [FBSDKBasicUtility objectForJSONString:parameters[@"state"] error:&error];
  _parameters.challenge = [FBSDKUtility URLDecode:state[@"challenge"]];

  NSString *domain = parameters[@"graph_domain"];
  _parameters.graphDomain = [domain copy];
}

- (void)setErrorWithDictionary:(NSDictionary *)parameters
{
  NSString *legacyErrorReason = parameters[@"error"];

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
  if (!handler) {
    return;
  }

  NSString *nonce = _parameters.nonceString ?: @"";
  NSString *appID = [FBSDKSettings appID] ?: @"";

  if (nonce.length == 0 || appID.length == 0) {
    _parameters.error = [FBSDKError errorWithCode:FBSDKErrorInvalidArgument message:@"Missing required parameters to exchange nonce for access token."];

    handler(_parameters);
    return;
  }

  FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] init];
  FBSDKGraphRequest *tokenRequest = [[FBSDKGraphRequest alloc]
                                     initWithGraphPath:@"oauth/access_token"
                                     parameters:@{ @"grant_type" : @"fb_exchange_nonce",
                                                   @"fb_exchange_nonce" : nonce,
                                                   @"client_id" : appID,
                                                   @"fields" : @"" }
                                     flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError
                                     | FBSDKGraphRequestFlagDisableErrorRecovery];
  __block FBSDKLoginCompletionParameters *parameters = _parameters;
  [connection addRequest:tokenRequest completionHandler:^(FBSDKGraphRequestConnection *requestConnection,
                                                          id result,
                                                          NSError *error) {
                                                            if (!error) {
                                                              parameters.accessTokenString = result[@"access_token"];
                                                              NSDate *expirationDate = [NSDate distantFuture];
                                                              if (result[@"expires_in"] && [result[@"expires_in"] integerValue] > 0) {
                                                                expirationDate = [NSDate dateWithTimeIntervalSinceNow:[result[@"expires_in"] integerValue]];
                                                              }
                                                              parameters.expirationDate = expirationDate;

                                                              NSDate *dataAccessExpirationDate = [NSDate distantFuture];
                                                              if (result[@"data_access_expiration_time"] && [result[@"data_access_expiration_time"] integerValue] > 0) {
                                                                dataAccessExpirationDate = [NSDate dateWithTimeIntervalSince1970:[result[@"data_access_expiration_time"] integerValue]];
                                                              }
                                                              parameters.dataAccessExpirationDate = dataAccessExpirationDate;
                                                            } else {
                                                              parameters.error = error;
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

  return [[FBSDKProfile alloc] initWithUserID:claims.sub
                                    firstName:nil
                                   middleName:nil
                                     lastName:nil
                                         name:claims.name
                                      linkURL:nil
                                  refreshDate:nil
                                     imageURL:imageURL
                                        email:claims.email];
}

@end

#endif
