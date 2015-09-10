/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBSDKMacros.h"
#import "FBSession.h"
#import "FBSessionAppEventsState.h"
#import "FBSystemAccountStoreAdapter.h"

FBSDK_EXTERN NSString *const FBLoginUXClientState;
FBSDK_EXTERN NSString *const FBLoginUXClientStateIsClientState;
FBSDK_EXTERN NSString *const FBLoginUXClientStateIsOpenSession;
FBSDK_EXTERN NSString *const FBLoginUXClientStateIsActiveSession;
FBSDK_EXTERN NSString *const FBLoginUXResponseTypeTokenAndSignedRequest;
FBSDK_EXTERN NSString *const FBLoginUXResponseType;

FBSDK_EXTERN NSString *const FBInnerErrorObjectKey;
FBSDK_EXTERN NSString *const FBSessionDidSetActiveSessionNotificationUserInfoIsOpening;
FBSDK_EXTERN NSString *const FacebookNativeApplicationLoginDomain;

@interface FBSession (Internal)

@property (readonly) FBSessionDefaultAudience lastRequestedSystemAudience;
@property (readonly, retain) FBSessionAppEventsState *appEventsState;
@property (readonly) NSThread *affinitizedThread;
@property (atomic, readonly) BOOL isRepairing;

- (void)refreshAccessToken:(NSString *)token expirationDate:(NSDate *)expireDate;
- (BOOL)shouldExtendAccessToken;
- (BOOL)shouldRefreshPermissions;
- (void)handleRefreshPermissions:(id)permissionsResponse;
- (void)closeAndClearTokenInformation:(NSError *)error;
- (void)clearAffinitizedThread;

+ (FBSession *)activeSessionIfExists;

+ (FBSession *)activeSessionIfOpen;

- (NSError *)errorLoginFailedWithReason:(NSString *)errorReason
                              errorCode:(NSString *)errorCode
                             innerError:(NSError *)innerError;

- (BOOL)openFromAccessTokenData:(FBAccessTokenData *)accessTokenData
              completionHandler:(FBSessionStateHandler)handler
   raiseExceptionIfInvalidState:(BOOL)raiseException;

+ (NSError *)sdkSurfacedErrorForNativeLoginError:(NSError *)nativeLoginError;

/*!
 * @abstract Attempts to build a detailed SDK error from an ACErrorDomain/ACErrorPermissionDenied error
 *
 * @param accountStoreError The error object from the Accounts framework to analyze
 * @param isReauthorize \c YES if the error code should reflect the reauthorize scenario, otherwise
 *                      \c NO to reflect the log in scenario
 * @param session The session to associate with the SDK error object, if any
 */
+ (NSError *)errorWithSystemAccountStoreDeniedError:(NSError *)accountStoreError
                                      isReauthorize:(BOOL)isReauthorize
                                         forSession:(FBSession *)session;

- (void)repairWithHandler:(FBSessionRequestPermissionResultHandler)handler;

+ (BOOL)openActiveSessionWithPermissions:(NSArray *)permissions
                            allowLoginUI:(BOOL)allowLoginUI
                           loginBehavior:(FBSessionLoginBehavior)loginBehavior
                                  isRead:(BOOL)isRead
                         defaultAudience:(FBSessionDefaultAudience)defaultAudience
                      fromViewController:(UIViewController *)fromViewController
                       completionHandler:(FBSessionStateHandler)handler;
@end
