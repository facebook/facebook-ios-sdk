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

#import <Accounts/Accounts.h>
#import <Foundation/Foundation.h>

#import "FBSession+Internal.h"
#import "FBTask.h"
#import "FBTaskCompletionSource.h"

typedef void (^FBRequestAccessToAccountsHandler)(NSString* oauthToken, NSError *accountStoreError);

/*
 @class

 @abstract Adapter around system account store APIs. Note this is only intended for internal
  consumption. If publicized, consider moving declarations to an internal only header.
*/
@interface FBSystemAccountStoreAdapter : NSObject

/*
 @abstract
   Requests access to the device's Facebook account for the given parameters.
 @param permissions the permissions
 @param defaultAudience the default audience
 @param isReauthorize a flag describing if this is a reauth request
 @param appID the app id
 @param session the session requesting access for
 @param handler the handler that will be invoked on completion (dispatched to the main thread). the oauthToken is nil on failure.
*/
- (void)requestAccessToFacebookAccountStore:(NSArray *)permissions
                            defaultAudience:(FBSessionDefaultAudience)defaultAudience
                              isReauthorize:(BOOL)isReauthorize
                                      appID:(NSString *)appID
                                    session:(FBSession *)session
                                    handler:(FBRequestAccessToAccountsHandler)handler;
/*!
 @abstract Same as `renewSystemAuthorization:` but represented as `FBTask`.
*/
- (FBTask *)renewSystemAuthorizationAsTask;

/*!
 @abstract Same as `requestAccessToFacebookAccountStore:handler:` but represented as `FBTask`
*/
- (FBTask *)requestAccessToFacebookAccountStoreAsTask:(FBSession *)session;
/*
 @abstract Sends a message to the device account store to renew the Facebook account credentials

 @param handler the handler that is invoked on completion (dispatched to the main thread).
*/
- (void)renewSystemAuthorization:(void( ^ )(ACAccountCredentialRenewResult result, NSError *error)) handler;

/*
 @abstract Gets the singleton instance.
*/
+ (FBSystemAccountStoreAdapter*) sharedInstance;

/*
 @abstract Sets the singleton instance, typically only for unit tests
*/
+ (void) setSharedInstance:(FBSystemAccountStoreAdapter *) instance;

/*
 @abstract Gets or sets the flag indicating if the next requestAccess call should block
  on a renew call.
*/
@property (assign) BOOL forceBlockingRenew;

/*
 @abstract Return YES if and only if access has been granted to the Facebook account
  on the device store. This should indicate that a `requestAccessToFacebookAcountStore`
  call will not trigger a UX
*/
@property (assign, readonly) BOOL canRequestAccessWithoutUI;

@end
