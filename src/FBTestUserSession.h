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

#import "FBAccessTokenData.h"
#import "FBSession.h"

/*!
 @class FBTestUserSession
 @abstract a "headless" (no UI) `FBSession` subclass that requires a token and is used for testing.

 @discussion This will generally be used with `FBTestUsersManager` to help exercise
  integration tests with Facebook. Use the class method `sessionWithAccessTokenData:` to construct
  instances.

  Note the supplied token data is not read until the session instance is "opened" (i.e., it will
  never be in a "TokenLoaded" state) and uses
  `[FBSessionTokenCachingStrategy nullCacheInstance]`.

  Furthermore, reauthorization calls will succeed as a no-op (no new permissions added). You may toggle
  the `treatReauthorizeAsCancellation` property to get cancellation treatment.
*/
@interface FBTestUserSession : FBSession

/*!
 @abstract returns an instance
 @discussion This should be used in place of any init methods.
*/
+ (instancetype)sessionWithAccessTokenData:(FBAccessTokenData *)tokenData;

/*!
 @abstract Flag to treat reauthorize calls as cancelled.
 @discussion
 Defaults to NO. If set to YES, reauthorize calls will receive a nil token
 as if the user had cancelled the reauthorize.
 */
@property (nonatomic, assign) BOOL treatReauthorizeAsCancellation;

/*!
 @abstract Flag to force extending a token expiration at the next opportunity.
*/
@property (nonatomic, assign) BOOL forceAccessTokenExtension;
@end
