/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAuthenticationStatusUtility.h"

#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKLogger.h"

static NSString *const FBSDKOIDCStatusPath = @"/platform/oidc/status";

@implementation FBSDKAuthenticationStatusUtility

static Class<FBSDKProfileProviding> _profileSetter;
static id<FBSDKSessionProviding> _sessionDataTaskProvider;
static Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting> _accessTokenWallet;
static Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting> _authenticationTokenWallet;

+ (nullable id<FBSDKSessionProviding>)sessionDataTaskProvider
{
  return _sessionDataTaskProvider;
}

+ (void)setSessionDataTaskProvider:(id<FBSDKSessionProviding>)sessionDataTaskProvider
{
  _sessionDataTaskProvider = sessionDataTaskProvider;
}

+ (nullable Class<FBSDKProfileProviding>)profileSetter
{
  return _profileSetter;
}

+ (void)setProfileSetter:(nullable Class<FBSDKProfileProviding>)profileSetter
{
  _profileSetter = profileSetter;
}

+ (nullable Class<FBSDKAccessTokenSetting, FBSDKAccessTokenSetting>)accessTokenWallet
{
  return _accessTokenWallet;
}

+ (void)setAccessTokenWallet:(nullable Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)accessTokenWallet
{
  _accessTokenWallet = accessTokenWallet;
}

+ (nullable Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting>)authenticationTokenWallet
{
  return _authenticationTokenWallet;
}

+ (void)setAuthenticationTokenWallet:(nullable Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting>)authenticationTokenWallet
{
  _authenticationTokenWallet = authenticationTokenWallet;
}

+ (void)configureWithProfileSetter:(Class<FBSDKProfileProviding>)profileSetter
           sessionDataTaskProvider:(id<FBSDKSessionProviding>)sessionDataTaskProvider
                 accessTokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)accessTokenWallet
         authenticationTokenWallet:(Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting>)authenticationTokenWallet;
{
  self.profileSetter = profileSetter;
  self.sessionDataTaskProvider = sessionDataTaskProvider;
  self.accessTokenWallet = accessTokenWallet;
  self.authenticationTokenWallet = authenticationTokenWallet;
}

#if FBTEST && DEBUG

+ (void)resetClassDependencies
{
  self.profileSetter = nil;
  self.sessionDataTaskProvider = nil;
  self.accessTokenWallet = nil;
  self.authenticationTokenWallet = nil;
}

#endif

+ (void)checkAuthenticationStatus
{
  NSURL *requestURL = [self _requestURL];
  if (!requestURL) {
    return;
  }

  NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
  if (request) {
    [[self.sessionDataTaskProvider dataTaskWithRequest:request
                                     completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
                                       if (!error) {
                                         fb_dispatch_on_main_thread(^{
                                           [self _handleResponse:response];
                                         });
                                       } else {
                                         [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorNetworkRequests
                                                                logEntry:error.localizedDescription];
                                       }
                                     }] resume];
  }
}

+ (void)_handleResponse:(NSURLResponse *)response
{
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

  if (httpResponse.statusCode != 200) {
    return;
  }

  if ([httpResponse respondsToSelector:@selector(allHeaderFields)]) {
    NSDictionary<NSString *, id> *header = httpResponse.allHeaderFields;
    NSString *status = [FBSDKTypeUtility dictionary:header objectForKey:@"fb-s" ofType:NSString.class];
    if ([status isEqualToString:@"not_authorized"]) {
      [self _invalidateCurrentSession];
    }
  }
}

+ (nullable NSURL *)_requestURL
{
  FBSDKAuthenticationToken *token = [self.authenticationTokenWallet currentAuthenticationToken];

  if (!token.tokenString) {
    return nil;
  }

  NSDictionary<NSString *, id> *params = @{@"id_token" : token.tokenString};
  NSError *error;

  NSURL *requestURL = [FBSDKInternalUtility.sharedUtility unversionedFacebookURLWithHostPrefix:@"m"
                                                                                          path:FBSDKOIDCStatusPath
                                                                               queryParameters:params
                                                                                         error:&error];
  return error == nil ? requestURL : nil;
}

+ (void)_invalidateCurrentSession
{
  [self.accessTokenWallet setCurrentAccessToken:nil];
  [self.authenticationTokenWallet setCurrentAuthenticationToken:nil];
  [self.profileSetter setCurrentProfile:nil];
}

@end

#endif
