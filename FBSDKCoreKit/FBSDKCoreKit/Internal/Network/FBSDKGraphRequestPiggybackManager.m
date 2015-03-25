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

#import "FBSDKGraphRequestPiggybackManager.h"

#import "FBSDKCoreKit+Internal.h"

static int const FBSDKTokenRefreshThresholdSeconds = 24 * 60 * 60;  // day
static int const FBSDKTokenRefreshRetrySeconds = 60 * 60;           // hour

@implementation FBSDKGraphRequestPiggybackManager

+ (void)addPiggybackRequests:(FBSDKGraphRequestConnection *)connection
{
  if ([FBSDKSettings appID].length > 0) {
    BOOL safeForPiggyback = YES;
    for (FBSDKGraphRequestMetadata *metadata in connection.requests) {
      if (![metadata.request.version isEqualToString:FBSDK_TARGET_PLATFORM_VERSION] ||
          [metadata.request hasAttachments]) {
        safeForPiggyback = NO;
        break;
      }
    }
    if (safeForPiggyback) {
      [[self class] addRefreshPiggyback:connection];
      [[self class] addServerConfigurationPiggyback:connection];
    }
  }
}

+ (void)addRefreshPiggyback:(FBSDKGraphRequestConnection *)connection
{
  // don't piggy back more than once an hour as a cheap way of
  // retrying in cases of errors and preventing duplicate refreshes.
  // obviously this is not foolproof but is simple and sufficient.
  static NSDate *lastRefreshTry;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    lastRefreshTry = [NSDate distantPast];
  });

  NSDate *now = [NSDate date];
  NSDate *tokenRefreshDate = [FBSDKAccessToken currentAccessToken].refreshDate;
  if (tokenRefreshDate &&
      [now timeIntervalSinceDate:lastRefreshTry] > FBSDKTokenRefreshRetrySeconds &&
      [now timeIntervalSinceDate:tokenRefreshDate] > FBSDKTokenRefreshThresholdSeconds) {
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"oauth/access_token"
                                                                   parameters:@{@"grant_type" : @"fb_extend_sso_token"}
                                                                        flags:FBSDKGraphRequestFlagDisableErrorRecovery];
    lastRefreshTry = [NSDate date];
    FBSDKAccessToken *expectedToken = [FBSDKAccessToken currentAccessToken];
    [connection addRequest:request completionHandler:^(FBSDKGraphRequestConnection *innerConnection, id result, NSError *error) {
      NSString *tokenString = result[@"access_token"];
      NSString *expirationString = result[@"expires_at"];
      FBSDKAccessToken *currentToken = [FBSDKAccessToken currentAccessToken];
      if (tokenString && expirationString) {
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSince1970:[expirationString doubleValue]];
        FBSDKAccessToken *refreshedToken = [[FBSDKAccessToken alloc] initWithTokenString:tokenString
                                                                             permissions:[currentToken.permissions allObjects]
                                                                     declinedPermissions:[currentToken.declinedPermissions allObjects]
                                                                                   appID:currentToken.appID
                                                                                  userID:currentToken.userID
                                                                          expirationDate:expirationDate
                                                                             refreshDate:[NSDate date]];
        if (expectedToken == currentToken) {
          [FBSDKAccessToken setCurrentAccessToken:refreshedToken];
        }
      }

    }];
  }
}

+ (void)addServerConfigurationPiggyback:(FBSDKGraphRequestConnection *)connection
{
  if ([FBSDKServerConfigurationManager cachedServerConfiguration]) {
    return;
  }
  NSString *appID = [FBSDKSettings appID];
  FBSDKGraphRequest *serverConfigurationRequest = [FBSDKServerConfigurationManager requestToLoadServerConfiguration:appID];
  [connection addRequest:serverConfigurationRequest
       completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {
         [FBSDKServerConfigurationManager processLoadRequestResponse:result error:error appID:appID];
       }];
}

@end
