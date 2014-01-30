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

extern NSString *kTestToken;
extern NSString *kTestAppId;

@class FBTestBlocker;
@protocol FBGraphObject;

@interface FBTests : SenTestCase

- (FBRequestHandler)handlerExpectingSuccessSignaling:(FBTestBlocker *)blocker;
- (FBRequestHandler)handlerExpectingFailureSignaling:(FBTestBlocker *)blocker;

// Used to test methods that dispatch blocks to the GCD main queue
- (void)waitForMainQueueToFinish;

// Methods related to session mocking.
- (FBSession *)createAndOpenSessionWithMockToken;
- (FBAccessTokenData *)createValidMockToken;
- (FBSessionTokenCachingStrategy *)createMockTokenCachingStrategyWithToken:(FBAccessTokenData *)token;
- (FBSessionTokenCachingStrategy *)createMockTokenCachingStrategyWithValidToken;
- (FBSessionTokenCachingStrategy *)createMockTokenCachingStrategyWithExpiredToken;

@end
