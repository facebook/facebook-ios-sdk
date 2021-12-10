/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKDeviceLoginManager.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKDeviceLoginCodeInfo+Internal.h"
#import "FBSDKDeviceLoginManagerResult+Internal.h"
#import "FBSDKDevicePoller.h"
#import "FBSDKDevicePolling.h"
#import "FBSDKDeviceRequestsHelper.h"
#import "FBSDKLoginConstants.h"

static NSMutableArray<FBSDKDeviceLoginManager *> *g_loginManagerInstances;

@interface FBSDKDeviceLoginManager ()

@property (nonatomic) FBSDKDeviceLoginCodeInfo *codeInfo;
@property (nonatomic) BOOL isCancelled;
@property (nonatomic) NSNetService *loginAdvertisementService;
@property (nonatomic) BOOL isSmartLoginEnabled;
@property (nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonatomic) id<FBSDKDevicePolling> poller;

@end

@implementation FBSDKDeviceLoginManager

+ (void)initialize
{
  if (self == FBSDKDeviceLoginManager.class) {
    g_loginManagerInstances = [NSMutableArray array];
  }
}

- (instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                   enableSmartLogin:(BOOL)enableSmartLogin
                graphRequestFactory:(nonnull id<FBSDKGraphRequestFactory>)graphRequestFactory
                       devicePoller:(id<FBSDKDevicePolling>)poller
{
  self = [self initWithPermissions:permissions enableSmartLogin:enableSmartLogin];
  _graphRequestFactory = graphRequestFactory;
  _poller = poller;
  return self;
}

- (instancetype)initWithPermissions:(NSArray<NSString *> *)permissions enableSmartLogin:(BOOL)enableSmartLogin
{
  id<FBSDKGraphRequestFactory> factory = [FBSDKGraphRequestFactory new];
  FBSDKDevicePoller *poller = [FBSDKDevicePoller new];
  if ((self = [super init])) {
    _permissions = [permissions copy];
    _isSmartLoginEnabled = enableSmartLogin;
    _graphRequestFactory = factory;
    _poller = poller;
  }
  return self;
}

- (void)start
{
  [FBSDKInternalUtility.sharedUtility validateAppID];
  [FBSDKTypeUtility array:g_loginManagerInstances addObject:self];

  NSDictionary<NSString *, id> *parameters = @{
    @"scope" : [self.permissions componentsJoinedByString:@","] ?: @"",
    @"redirect_uri" : self.redirectURL.absoluteString ?: @"",
    FBSDK_DEVICE_INFO_PARAM : [FBSDKDeviceRequestsHelper getDeviceInfo],
  };
  id<FBSDKGraphRequest> request = [_graphRequestFactory createGraphRequestWithGraphPath:@"device/login"
                                                                             parameters:parameters
                                                                            tokenString:[FBSDKInternalUtility.sharedUtility validateRequiredClientAccessToken]
                                                                             HTTPMethod:@"POST"
                                                                                  flags:FBSDKGraphRequestFlagNone];
  request.graphErrorRecoveryDisabled = YES;
  FBSDKGraphRequestCompletion completion = ^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
    if (error) {
      [self _processError:error];
      return;
    }

    NSString *identifier = [FBSDKTypeUtility dictionary:result objectForKey:@"code" ofType:NSString.class];
    if (identifier) {
      NSString *loginCode = [FBSDKTypeUtility dictionary:result objectForKey:@"user_code" ofType:NSString.class];
      NSString *verificationURL = [FBSDKTypeUtility dictionary:result objectForKey:@"verification_uri" ofType:NSString.class];
      double expiresIn = [[FBSDKTypeUtility dictionary:result objectForKey:@"expires_in" ofType:NSString.class] doubleValue];
      long interval = [[FBSDKTypeUtility dictionary:result objectForKey:@"interval" ofType:NSNumber.class] longValue];

      self->_codeInfo = [[FBSDKDeviceLoginCodeInfo alloc]
                         initWithIdentifier:identifier
                         loginCode:loginCode
                         verificationURL:[NSURL URLWithString:verificationURL]
                         expirationDate:[NSDate.date dateByAddingTimeInterval:expiresIn]
                         pollingInterval:interval];

      if (self->_isSmartLoginEnabled) {
        [FBSDKDeviceRequestsHelper startAdvertisementService:self->_codeInfo.loginCode
                                                withDelegate:self
        ];
      }

      [self.delegate deviceLoginManager:self startedWithCodeInfo:self->_codeInfo];
      [self _schedulePoll:self->_codeInfo.pollingInterval];
    } else {
      [self _notifyError:[FBSDKError errorWithCode:FBSDKErrorUnknown message:@"Unable to create a login request"]];
    }
  };
  [request startWithCompletion:completion];
}

- (void)cancel
{
  [FBSDKDeviceRequestsHelper cleanUpAdvertisementService:self];
  _isCancelled = YES;
  [g_loginManagerInstances removeObject:self];
}

#pragma mark - Private impl

- (void)_notifyError:(NSError *)error
{
  [FBSDKDeviceRequestsHelper cleanUpAdvertisementService:self];
  [self.delegate deviceLoginManager:self
                completedWithResult:nil
                              error:error];
  [g_loginManagerInstances removeObject:self];
}

- (void)_notifyToken:(NSString *)tokenString withExpirationDate:(NSDate *)expirationDate withDataAccessExpirationDate:(NSDate *)dataAccessExpirationDate
{
  [FBSDKDeviceRequestsHelper cleanUpAdvertisementService:self];
  void (^completeWithResult)(FBSDKDeviceLoginManagerResult *) = ^(FBSDKDeviceLoginManagerResult *result) {
    [self.delegate deviceLoginManager:self completedWithResult:result error:nil];
    [g_loginManagerInstances removeObject:self];
  };

  if (tokenString) {
    id<FBSDKGraphRequest> request = [_graphRequestFactory createGraphRequestWithGraphPath:@"me"
                                                                               parameters:@{@"fields" : @"id,permissions"}
                                                                              tokenString:tokenString
                                                                               HTTPMethod:@"GET"
                                                                                    flags:FBSDKGraphRequestFlagDisableErrorRecovery];
    FBSDKGraphRequestCompletion completion = ^(id<FBSDKGraphRequestConnecting> connection, id rawResult, NSError *error) {
      NSDictionary<NSString *, id> *graphResult = [FBSDKTypeUtility dictionaryValue:rawResult];
      if (!error && graphResult) {
        NSString *userID = [FBSDKTypeUtility dictionary:graphResult objectForKey:@"id" ofType:NSString.class];
        NSDictionary<NSString *, id> *permissionResult = [FBSDKTypeUtility dictionary:graphResult objectForKey:@"permissions" ofType:NSDictionary.class];
        if (userID && permissionResult) {
          NSMutableSet<NSString *> *permissions = [NSMutableSet set];
          NSMutableSet<NSString *> *declinedPermissions = [NSMutableSet set];
          NSMutableSet<NSString *> *expiredPermissions = [NSMutableSet set];

          [FBSDKInternalUtility.sharedUtility extractPermissionsFromResponse:permissionResult
                                                          grantedPermissions:permissions
                                                         declinedPermissions:declinedPermissions
                                                          expiredPermissions:expiredPermissions];
          FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:tokenString
                                                                            permissions:permissions.allObjects
                                                                    declinedPermissions:declinedPermissions.allObjects
                                                                     expiredPermissions:expiredPermissions.allObjects
                                                                                  appID:FBSDKSettings.sharedSettings.appID
                                                                                 userID:userID
                                                                         expirationDate:expirationDate
                                                                            refreshDate:nil
                                                               dataAccessExpirationDate:dataAccessExpirationDate];
          FBSDKDeviceLoginManagerResult *result = [[FBSDKDeviceLoginManagerResult alloc] initWithToken:accessToken
                                                                                           isCancelled:NO];
          FBSDKAccessToken.currentAccessToken = accessToken;
          completeWithResult(result);
          return;
        }
      }
      NSError *wrappedError = [FBSDKError errorWithDomain:FBSDKLoginErrorDomain
                                                     code:FBSDKErrorUnknown
                                                  message:@"Unable to fetch permissions for token"
                                          underlyingError:error];
      [self _notifyError:wrappedError];
    };
    [request startWithCompletion:completion];
  } else {
    _isCancelled = YES;
    FBSDKDeviceLoginManagerResult *result = [[FBSDKDeviceLoginManagerResult alloc] initWithToken:nil isCancelled:YES];
    completeWithResult(result);
  }
}

- (void)_processError:(NSError *)error
{
  FBSDKDeviceLoginError code = [error.userInfo[FBSDKGraphRequestErrorGraphErrorSubcodeKey] unsignedIntegerValue];
  switch (code) {
    case FBSDKDeviceLoginErrorAuthorizationPending:
      [self _schedulePoll:_codeInfo.pollingInterval];
      break;
    case FBSDKDeviceLoginErrorCodeExpired:
    case FBSDKDeviceLoginErrorAuthorizationDeclined:
      [self _notifyToken:nil withExpirationDate:nil withDataAccessExpirationDate:nil];
      break;
    case FBSDKDeviceLoginErrorExcessivePolling:
      [self _schedulePoll:_codeInfo.pollingInterval * 2];
    default:
      [self _notifyError:error];
      break;
  }
}

- (void)_schedulePoll:(NSUInteger)interval
{
  [_poller scheduleBlock:^{
             if (self->_isCancelled) {
               return;
             }

             NSDictionary<NSString *, id> *parameters = @{ @"code" : self->_codeInfo.identifier };
             id<FBSDKGraphRequest> request = [self->_graphRequestFactory createGraphRequestWithGraphPath:@"device/login_status"
                                                                                              parameters:parameters
                                                                                             tokenString:[FBSDKInternalUtility.sharedUtility validateRequiredClientAccessToken]
                                                                                              HTTPMethod:@"POST"
                                                                                                   flags:FBSDKGraphRequestFlagNone];
             request.graphErrorRecoveryDisabled = YES;
             FBSDKGraphRequestCompletion completion = ^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
               if (self->_isCancelled) {
                 return;
               }
               if (error) {
                 [self _processError:error];
               } else {
                 NSString *tokenString = [FBSDKTypeUtility dictionary:result objectForKey:@"access_token" ofType:NSString.class];
                 NSDate *expirationDate = NSDate.distantFuture;
                 NSInteger expiresIn = [[FBSDKTypeUtility dictionary:result objectForKey:@"expires_in" ofType:NSString.class] integerValue];
                 if (expiresIn > 0) {
                   expirationDate = [NSDate dateWithTimeIntervalSinceNow:expiresIn];
                 }

                 NSDate *dataAccessExpirationDate = NSDate.distantFuture;
                 NSInteger dataAccessExpirationTime = [[FBSDKTypeUtility dictionary:result objectForKey:@"data_access_expiration_time" ofType:NSString.class] integerValue];
                 if (dataAccessExpirationTime > 0) {
                   dataAccessExpirationDate = [NSDate dateWithTimeIntervalSince1970:dataAccessExpirationTime];
                 }

                 if (tokenString) {
                   [self _notifyToken:tokenString withExpirationDate:expirationDate withDataAccessExpirationDate:dataAccessExpirationDate];
                 } else {
                   NSError *unknownError = [FBSDKError errorWithDomain:FBSDKLoginErrorDomain
                                                                  code:FBSDKErrorUnknown
                                                               message:@"Device Login poll failed. No token nor error was found."];
                   [self _notifyError:unknownError];
                 }
               }
             };
             [request startWithCompletion:completion];
           } interval:interval];
}

- (void)netService:(NSNetService *)sender
     didNotPublish:(NSDictionary<NSString *, NSNumber *> *)errorDict
{
  // Only cleanup if the publish error is from our advertising service
  if ([FBSDKDeviceRequestsHelper isDelegate:self forAdvertisementService:sender]) {
    [FBSDKDeviceRequestsHelper cleanUpAdvertisementService:self];
  }
}

// MARK: Test Helpers

- (void)setCodeInfo:(FBSDKDeviceLoginCodeInfo *)codeInfo
{
  _codeInfo = codeInfo;
}

@end
