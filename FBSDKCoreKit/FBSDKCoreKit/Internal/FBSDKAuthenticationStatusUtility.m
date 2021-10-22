/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAuthenticationStatusUtility.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAccessToken.h"
#import "FBSDKAuthenticationToken.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKLogger.h"
#import "FBSDKProfile.h"

static NSString *const FBSDKOIDCStatusPath = @"/platform/oidc/status";

@implementation FBSDKAuthenticationStatusUtility

+ (void)checkAuthenticationStatus
{
  NSURL *requestURL = [self _requestURL];
  if (!requestURL) {
    return;
  }

  NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
  if (request) {
    [[NSURLSession.sharedSession dataTaskWithRequest:request
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
    NSDictionary<NSString *, id> *header = [httpResponse allHeaderFields];
    NSString *status = [FBSDKTypeUtility dictionary:header objectForKey:@"fb-s" ofType:NSString.class];
    if ([status isEqualToString:@"not_authorized"]) {
      [self _invalidateCurrentSession];
    }
  }
}

+ (nullable NSURL *)_requestURL
{
  FBSDKAuthenticationToken *token = FBSDKAuthenticationToken.currentAuthenticationToken;

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
  FBSDKAccessToken.currentAccessToken = nil;
  FBSDKAuthenticationToken.currentAuthenticationToken = nil;
  FBSDKProfile.currentProfile = nil;
}

@end

#endif
