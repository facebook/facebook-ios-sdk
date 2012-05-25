/*
 * Copyright 2012 Facebook
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

#if defined (DEBUG)
    #define SAFE_TO_USE_FBTESTSESSION
#endif

#if !defined(SAFE_TO_USE_FBTESTSESSION)
    #pragma message ("warning: using FBTestSession in non-DEBUG code -- ensure this is what you really want")
#endif

/*!
 @class FBTestSession
 
 @abstract
 Implements an FBSession subclass that knows about test users for a particular
 application. This should never be used from a real application, but may be useful
 for writing unit tests, etc.
 
 @discussion
 Facebook allows developers to create test accounts for testing their applications'
 Facebook integration (see https://developers.facebook.com/docs/test_users/). This class
 simplifies use of these accounts for writing unit tests. It is not designed for use in
 production application code.
 
 The main use case for this class is using sessionForUnitTestingWithPermissions:sharedTestUser:
 to create a session for a test user. Two modes are supported. In "shared" mode, an attempt
 is made to find an existing test user that has the required permissions and, if it is not
 currently in use by another FBTestSession, just use that user. If no such user is available,
 a new one is created with the required permissions. In "non-shared" mode, designed for
 scenarios which require a new user in a known clean state, a new test user will always be
 created, and it will be automatically deleted when the FBTestSession is closed.
 
 Note that the shared test user functionality depends on a naming convention for the test users.
 It is important that any testing of functionality which will mutate the permissions for a
 test user NOT use a shared test user, or this scheme will break down. If a shared test user
 seems to be in an invalid state, it can be deleted manually via the Web interface at
 https://developers.facebook.com/apps/APP_ID/permissions?role=test+users.
 
 @unsorted
 */
@interface FBTestSession : FBSession

/// The app access token (composed of app ID and secret) to use for accessing test users.
@property (readonly, copy) NSString *appAccessToken;
/// The ID of the test user associated with this session.
@property (readonly, copy) NSString *testUserID;

/*!
 @abstract
 Constructor helper to create a session for use in unit tests
 
 @description
 This method creates a session object which creates a test user on open, and destroys the user on
 close; This method should not be used in application code -- but is useful for creating unit tests
 that use the Facebook iOS SDK.
 
 @param permissions     array of strings naming permissions to authorize; nil indicates 
 a common default set of permissions should be used for unit testing
 */
+ (id)sessionForUnitTestingWithPermissions:(NSArray*)permissions;

@end
