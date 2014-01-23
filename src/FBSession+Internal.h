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

#import "FBSession.h"
#import "FBSessionAppEventsState.h"
#import "FBSystemAccountStoreAdapter.h"

extern NSString *const FBLoginUXClientState;
extern NSString *const FBLoginUXClientStateIsClientState;
extern NSString *const FBLoginUXClientStateIsOpenSession;
extern NSString *const FBLoginUXClientStateIsActiveSession;
extern NSString *const FBLoginUXResponseTypeToken;
extern NSString *const FBLoginUXResponseType;

extern NSString *const FBInnerErrorObjectKey;
extern NSString *const FBSessionDidSetActiveSessionNotificationUserInfoIsOpening;
extern NSString *const FacebookNativeApplicationLoginDomain;

@interface FBSession (Internal)

@property (readonly) FBSessionDefaultAudience lastRequestedSystemAudience;
@property (readonly, retain) FBSessionAppEventsState *appEventsState;
@property (readonly) NSThread *affinitizedThread;
@property (atomic, readonly) BOOL isRepairing;

- (void)refreshAccessToken:(NSString*)token expirationDate:(NSDate*)expireDate;
- (BOOL)shouldExtendAccessToken;
- (BOOL)shouldRefreshPermissions;
- (void)refreshPermissions:(NSArray *)permissions;
- (void)closeAndClearTokenInformation:(NSError*) error;
- (void)clearAffinitizedThread;

+ (FBSession*)activeSessionIfExists;

+ (FBSession*)activeSessionIfOpen;

- (NSError*)errorLoginFailedWithReason:(NSString*)errorReason
                             errorCode:(NSString*)errorCode
                            innerError:(NSError*)innerError;

- (BOOL)openFromAccessTokenData:(FBAccessTokenData *)accessTokenData
              completionHandler:(FBSessionStateHandler) handler
   raiseExceptionIfInvalidState:(BOOL)raiseException;

+ (NSError *)sdkSurfacedErrorForNativeLoginError:(NSError *)nativeLoginError;

- (void)repairWithHandler:(FBSessionRequestPermissionResultHandler) handler;

+ (BOOL)openActiveSessionWithPermissions:(NSArray*)permissions
                            allowLoginUI:(BOOL)allowLoginUI
                         defaultAudience:(FBSessionDefaultAudience)defaultAudience
                       completionHandler:(FBSessionStateHandler)handler;

+ (BOOL)openActiveSessionWithPermissions:(NSArray*)permissions
                           loginBehavior:(FBSessionLoginBehavior)loginBehavior
                                  isRead:(BOOL)isRead
                         defaultAudience:(FBSessionDefaultAudience)defaultAudience
                       completionHandler:(FBSessionStateHandler)handler;
@end
