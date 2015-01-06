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

#import <Foundation/Foundation.h>

@class FBAccessTokenData;

/*!
 @typedef

 @abstract Callback block for returning an array of `FBAccessTokenData` (and possibly `NSNull` instances); or an error.
 */
typedef void (^FBTestUsersManagerRetrieveTestAccountTokensHandler)(NSArray *tokens, NSError *error) ;

/*!
 @typedef

 @abstract Callback block for removing a test user.
 */
typedef void (^FBTestUsersManagerRemoveTestAccountHandler)(NSError *error) ;


/*!
 @class FBTestUsersManager
 @abstract Provides methods for managing test accounts for testing Facebook integration.

 @discussion Facebook allows developers to create test accounts for testing their applications'
 Facebook integration (see https://developers.facebook.com/docs/test_users/). This class
 simplifies use of these accounts for writing tests. It is not designed for use in
 production application code.

 This class will make Graph API calls on behalf of your app to manage test accounts and requires
 an app id and app secret. You will typically use this class to write unit or integration tests.
 Make sure you NEVER include your app secret in your production app.
*/
@interface FBTestUsersManager : NSObject

/*!
 @abstract construct or return the shared instance
 @param appId the Facebook app id
 @param appSecret the Facebook app secret
*/
+ (instancetype)sharedInstanceForAppId:(NSString *)appId appSecret:(NSString *)appSecret;

/*!
 @abstract retrieve `FBAccessTokenData` instances for test accounts with the specific permissions.
 @param arraysOfPermissions an array of permissions arrays, such as @[ @[@"email"], @[@"user_birthday"]]
  if you needed two test accounts with email and birthday permissions, respectively. You can pass in empty nested arrays
  such as @[ @[], @[] ] if you need two arbitrary test accounts. For convenience, passing nil is treated as @[ @[] ]
  for fetching a single test user.
 @param createIfNotFound if YES, new test accounts are created if no test accounts existed that fit the permissions
  requirement
 @param handler the callback to invoke which will return an array of `FBAccessTokenData` instances or an `NSError`.
  If param `createIfNotFound` is NO, the array may contain `[NSNull null]` instances.

 @discussion If you are requesting test accounts with differing number of permissions, try to order
  `arrayOfPermissionsArrays` so that the most number of permissions come first to minimize creation of new
  test accounts.
 */
- (void)requestTestAccountTokensWithArraysOfPermissions:(NSArray *)arraysOfPermissions
                                       createIfNotFound:(BOOL)createIfNotFound
                                      completionHandler:(FBTestUsersManagerRetrieveTestAccountTokensHandler)handler;

/*!
 @abstract add a test account with the specified permissions
*/
- (void)addTestAccountWithPermissions:(NSArray *)permissions
                    completionHandler:(FBTestUsersManagerRetrieveTestAccountTokensHandler)handler;

/*!
 @abstract remove a test account for the given user id
*/
- (void)removeTestAccount:(NSString *)userId completionHandler:(FBTestUsersManagerRemoveTestAccountHandler)handler;

@end
