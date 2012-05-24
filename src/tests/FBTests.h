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

#import <SenTestingKit/SenTestingKit.h>

// The following #defines are designed as a convenience during development
// to disable certain categories of tests. They should never be left on
// in committed code.

//#define FBIOSSDK_SKIP_CACHE_TESTS
//#define FBIOSSDK_SKIP_COMMON_REQUEST_TESTS
//#define FBIOSSDK_SKIP_GRAPH_OBJECT_TESTS
//#define FBIOSSDK_SKIP_OPEN_GRAPH_ACTION_TESTS
//#define FBIOSSDK_SKIP_SESSION_TESTS
//#define FBIOSSDK_SKIP_BATCH_REQUEST_TESTS

@class FBSession;

// Base class for unit-tests that use test users; ensures that all test users
// created by a unit-test are deleted (by invalidating their session) during
// tear-down.
@interface FBTests : SenTestCase

- (FBSession *)loginTestUserWithPermissions:(NSString *)firstPermission, ...;
- (FBSession *)loginSession:(FBSession *)session;
- (void)makeTestUserInSession:(FBSession*)session1 friendsWithTestUserInSession:(FBSession*)session2;

- (void)validateGraphObjectWithId:(NSString*)idString hasProperties:(NSArray*)propertyNames withSession:(FBSession*)session;
- (void)postAndValidateWithSession:(FBSession*)session graphPath:(NSString*)graphPath graphObject:(id)graphObject hasProperties:(NSArray*)propertyNames;

@end
