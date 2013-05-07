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

// Methods here are meant to be used only by internal subclasses of FBSession
// and not by any other classes, external or internal.
@interface FBSession (Protected)

// Permissions are technically associated with a FBAccessTokenData instance
// but we support initializing an FBSession before acquiring a token. This property
// tracks that initialized array so that the pass-through permissions property
// can essentially return self.FBAccessTokenData.permissions ?: self.initializedPermissions
@property(readonly, copy) NSArray *initializedPermissions;

- (BOOL)transitionToState:(FBSessionState)state
           andUpdateToken:(NSString*)token
        andExpirationDate:(NSDate*)date
              shouldCache:(BOOL)shouldCache
                loginType:(FBSessionLoginType)loginType;
- (void)transitionAndCallHandlerWithState:(FBSessionState)status
                                    error:(NSError*)error
                                    token:(NSString*)token
                           expirationDate:(NSDate*)date
                              shouldCache:(BOOL)shouldCache
                                loginType:(FBSessionLoginType)loginType;
- (void)authorizeWithPermissions:(NSArray*)permissions
                        behavior:(FBSessionLoginBehavior)behavior
                 defaultAudience:(FBSessionDefaultAudience)audience
                   isReauthorize:(BOOL)isReauthorize;
- (BOOL)handleReauthorize:(NSDictionary*)parameters
              accessToken:(NSString*)accessToken;

@end
