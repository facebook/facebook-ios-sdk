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

#import "FBSession+FBSessionLoginStrategy.h"
#import "FBSessionAuthLogger.h"
#import "FBSessionLoginStrategyParams.h"
#import "FacebookSDK.h"

// these are helpful macros for testing various login methods, should always checkin as NO/NO
#define TEST_DISABLE_MULTITASKING_LOGIN NO
#define TEST_DISABLE_FACEBOOKLOGIN NO
#define TEST_DISABLE_FACEBOOKNATIVELOGIN NO

// Internal protocol that describes a type that can perform authorization.
// It's possible for a strategy to compose over other strategies. See `FBSessionAppSwitchingLoginStategy`.
@protocol FBSessionLoginStrategy <NSObject>

@required

/*!
 @method

 @abstract Instructs the instance to attempt to perform the login.

 @param params A collection of parameters typically used to evalute if a given strategy should be invoked.
 @param session The session instance.
 @param logger The logger instance.

 @discussion
 A return value of 'NO' indicates
 another login strategy should be tried. A value of 'YES' means the strategy has handled the login flow
 and no other strategies should be tried (note this does not necessarily mean the login was successful).
*/
- (BOOL)tryPerformAuthorizeWithParams:(FBSessionLoginStrategyParams *)params session:(FBSession *)session logger:(FBSessionAuthLogger *)logger;

/*! @
 abstract Gets the methodName describing this login strategy, typically for external logging.
 @discussion This should only be invoked if a `tryPerformAuthorizeWithParams:...` call returned YES.
*/
@property (readonly) NSString *methodName;

@end










