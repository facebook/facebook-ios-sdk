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

#import "FBSDKDeviceLoginManager.h"
#import "FBSDKDeviceLoginManagerResult+Internal.h"

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKDeviceLoginCodeInfo+Internal.h"
#import "FBSDKTVOSConstants.h"
#import "FBSDKTVOSError.h"

static NSMutableArray<FBSDKDeviceLoginManager *> *g_loginManagerInstances;

@implementation FBSDKDeviceLoginManager {
  FBSDKDeviceLoginCodeInfo *_codeInfo;
  BOOL _isCancelled;
}

+ (void)initialize
{
  if (self == [FBSDKDeviceLoginManager class]) {
    g_loginManagerInstances = [NSMutableArray array];
  }
}

- (instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
{
  if ((self = [super init])) {
    _permissions = [permissions copy];
  }
  return self;
}

- (void)start
{
  [FBSDKInternalUtility validateAppID];
  [g_loginManagerInstances addObject:self];

  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                initWithGraphPath:@"oauth/device"
                                parameters:@{
                                             @"type" : @"device_code",
                                             @"client_id" : [FBSDKSettings appID],
                                             @"scope" : [self.permissions componentsJoinedByString:@","] ?: @""
                                             }
                                HTTPMethod:@"POST"];
  [request setGraphErrorRecoveryDisabled:YES];
  [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    if (error) {
      [self _processError:error];
      return;
    }

    _codeInfo = [[FBSDKDeviceLoginCodeInfo alloc]
                                          initWithIdentifier:result[@"code"]
                                          loginCode:result[@"user_code"]
                                          verificationURL:[NSURL URLWithString:result[@"verification_uri"]]
                                          expirationDate:[[NSDate date] dateByAddingTimeInterval:[result[@"expires_in"] doubleValue]]
                                          pollingInterval:[result[@"interval"] integerValue]];
    [self.delegate deviceLoginManager:self
                  startedWithCodeInfo:_codeInfo];
    [self _schedulePoll:_codeInfo.pollingInterval];
  }];
 }

- (void)cancel
{
  _isCancelled = YES;
  [g_loginManagerInstances removeObject:self];
}

#pragma mark - Private impl

- (void)_notifyError:(NSError *)error
{
  [self.delegate deviceLoginManager:self
                completedWithResult:nil
                              error:error];
  [g_loginManagerInstances removeObject:self];
}

- (void)_notifyToken:(NSString *)tokenString
{
  void(^completeWithResult)(FBSDKDeviceLoginManagerResult *) = ^(FBSDKDeviceLoginManagerResult *result) {
    [self.delegate deviceLoginManager:self completedWithResult:result error:nil];
    [g_loginManagerInstances removeObject:self];
  };

  if (tokenString) {
    FBSDKGraphRequest *permissionsRequest =
    [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                      parameters:@{@"fields": @"id,permissions"}
                                     tokenString:tokenString
                                      HTTPMethod:@"GET"
                                           flags:FBSDKGraphRequestFlagDisableErrorRecovery];
    [permissionsRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id permissionRawResult, NSError *error) {
      NSString *userID = permissionRawResult[@"id"];
      NSDictionary *permissionResult = permissionRawResult[@"permissions"];
      if (error ||
          !userID ||
          !permissionResult) {
        NSError *wrappedError = [FBSDKTVOSError errorWithCode:FBSDKTVOSUnknownErrorCode
                                                      message:@"Unable to fetch permissions for token"
                                              underlyingError:error];
        [self _notifyError:wrappedError];
      } else {
        NSMutableSet<NSString *> *permissions = [NSMutableSet set];
        NSMutableSet<NSString *> *declinedPermissions = [NSMutableSet set];

        [FBSDKInternalUtility extractPermissionsFromResponse:permissionResult
                                          grantedPermissions:permissions
                                         declinedPermissions:declinedPermissions];
        FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:tokenString
                                                                          permissions:permissions.allObjects
                                                                  declinedPermissions:declinedPermissions.allObjects
                                                                                appID:[FBSDKSettings appID]
                                                                               userID:userID
                                                                       expirationDate:nil
                                                                          refreshDate:nil];
        FBSDKDeviceLoginManagerResult *result = [[FBSDKDeviceLoginManagerResult alloc] initWithToken:accessToken
                                                                                         isCancelled:NO];
        completeWithResult(result);
      }
    }];
  } else {
    _isCancelled = YES;
    FBSDKDeviceLoginManagerResult *result = [[FBSDKDeviceLoginManagerResult alloc] initWithToken:nil isCancelled:YES];
    completeWithResult(result);
  }
}

- (void)_processError:(NSError *)error
{
  NSString *message = [error.userInfo[FBSDKErrorDeveloperMessageKey] lowercaseString];
  if ([message isEqualToString:@"authorization_pending"]) {
    [self _schedulePoll:_codeInfo.pollingInterval];
  } else if ([message isEqualToString:@"code_expired"] ||
             [message isEqualToString:@"authorization_declined"]) {
    [self _notifyToken:nil];
  } else if ([message isEqualToString:@"invalid api method"]) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                           logEntry:@"Device Login disabled. Verify you have enabled \"Login from devices\" in your app settings (Visit https://developers.facebook.com/apps for your app. Then check Settings > Advanced > OAuth Settings)"];
    [self _notifyError:error];
  } else if ([message isEqualToString:@"slow_down"]) {
    [self _schedulePoll:_codeInfo.pollingInterval * 2];
  } else {
    [self _notifyError:error];
  }
}

- (void)_schedulePoll:(NSUInteger)interval
{
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   if (_isCancelled) {
                     return;
                   }

                   FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                                 initWithGraphPath:@"oauth/device"
                                                 parameters:@{
                                                              @"type" : @"device_token",
                                                              @"client_id" : [FBSDKSettings appID],
                                                              @"code" : _codeInfo.identifier
                                                              }
                                                 HTTPMethod:@"POST"];
                   [request setGraphErrorRecoveryDisabled:YES];
                   [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                     if (_isCancelled) {
                       return;
                     }
                     if (error) {
                       [self _processError:error];
                     } else {
                       NSString *tokenString = result[@"access_token"];
                       if (tokenString) {
                         [self _notifyToken:tokenString];
                       } else {
                         NSError *unknownError = [FBSDKTVOSError errorWithCode:FBSDKTVOSUnknownErrorCode
                                                                       message:@"Device Login poll failed. No token nor error was found."];
                         [self _notifyError:unknownError];
                       }
                     }
                   }];
                 });
}
@end
