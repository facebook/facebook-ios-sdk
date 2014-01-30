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

#import <SenTestingKit/SenTestingKit.h>
#import "FBTestSession.h"
#import "FBRequestConnection.h"

// The following #defines are designed as a convenience during development
// to disable certain categories of tests. They should never be left on
// in committed code.

//#define FACEBOOKSDK_SKIP_CACHE_TESTS
//#define FACEBOOKSDK_SKIP_COMMON_REQUEST_TESTS
//#define FACEBOOKSDK_SKIP_GRAPH_OBJECT_TESTS
//#define FACEBOOKSDK_SKIP_OPEN_GRAPH_ACTION_TESTS
//#define FACEBOOKSDK_SKIP_SESSION_TESTS
//#define FACEBOOKSDK_SKIP_BATCH_REQUEST_TESTS
//#define FACEBOOKSDK_SKIP_REQUEST_CONNECTION_TESTS
//#define FACEBOOKSDK_SKIP_TEST_SESSION_TESTS
//#define FACEBOOKSDK_SKIP_CONTENT_LINK_TESTS
//#define FACEBOOKSDK_SKIP_FBACCESSTOKEN_TESTS

@class FBTestBlocker;
@protocol FBGraphObject;

// Base class for unit-tests that use test users; ensures that all test users
// created by a unit-test are deleted (by invalidating their session) during
// tear-down.
@interface FBIntegrationTests : SenTestCase

// For many test case scenarios, we just need a single session with a set of permissions
// that can be shared and used by each individual test. For the simple case, this is that
// session.
@property (readonly, retain) FBTestSession *defaultTestSession;

- (FBRequestHandler)handlerExpectingSuccessSignaling:(FBTestBlocker *)blocker;
- (FBRequestHandler)handlerExpectingFailureSignaling:(FBTestBlocker *)blocker;

- (FBTestSession *)getSessionWithSharedUserWithPermissions:(NSArray *)permissions;
- (FBTestSession *)getSessionWithSharedUserWithPermissions:(NSArray *)permissions
                                             uniqueUserTag:(NSString *)uniqueUserTag;

- (FBTestSession *)loginSession:(FBTestSession *)session;
- (void)makeTestUserInSession:(FBTestSession *)session1 friendsWithTestUserInSession:(FBTestSession *)session2;

- (void)validateGraphObject:(id<FBGraphObject>)graphObject
              hasProperties:(NSArray *)propertyNames;
- (void)validateGraphObjectWithId:(NSString *)idString
                    hasProperties:(NSArray *)propertyNames
                      withSession:(FBSession *)session
                          blocker:(FBTestBlocker *)blocker;
- (void)postAndValidateWithSession:(FBSession *)session
                         graphPath:(NSString *)graphPath
                       graphObject:(id)graphObject
                     hasProperties:(NSArray *)propertyNames;
- (id)batchedPostAndGetWithSession:(FBSession *)session
                         graphPath:(NSString *)graphPath
                       graphObject:(id)graphObject;
- (UIImage *)createSquareTestImage:(int)size;

// Subclasses can define this to get defaultTestSessions with specific permissions.
// The set of permissions should be static, as no guarantee is made how many times this will be called.
// The default is nil.
- (NSArray *)permissionsForDefaultTestSession;
- (void)logRequestsAndConnections;

@end
