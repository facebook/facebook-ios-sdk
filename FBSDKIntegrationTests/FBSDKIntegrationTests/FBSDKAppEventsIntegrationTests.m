// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <OHHTTPStubs/OHHTTPStubs.h>

#import <XCTest/XCTest.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKIntegrationTestCase.h"
#import "FBSDKTestBlocker.h"

@class FBSDKAppEventsState;

@interface FBSDKAppEventsUtility (FBSDKAppEventsIntegrationTests)
+ (void)clearLibraryFiles;
@end

@interface FBSDKAppEvents(FBSDKAppEventsIntegrationTests)
@property (nonatomic, assign) BOOL disableTimer;
@end

@interface FBSDKTimeSpentData (FBSDKAppEventsIntegrationTests)
+ (FBSDKTimeSpentData *)singleton;
@property (nonatomic) NSInteger numSecondsIdleToBeNewSession;
@end

@interface FBSDKAppEventsIntegrationTests : FBSDKIntegrationTestCase

@end

@implementation FBSDKAppEventsIntegrationTests

// useful for debugging
//+ (void)setUp {
//  [FBSDKSettings setLoggingBehavior:[NSSet setWithObjects:FBSDKLoggingBehaviorAppEvents, nil]];
//}
//
//+ (void)tearDown {
//  [FBSDKSettings setLoggingBehavior:[NSSet setWithObject:FBSDKLoggingBehaviorDeveloperErrors]];
//}

- (void)setUp {
  [super setUp];
  [FBSDKSettings setAppID:self.testAppID];
  // clear any persisted events
  [FBSDKAppEventsStateManager clearPersistedAppEventsStates];
}

- (void)tearDown {
  [super tearDown];
  [FBSDKAppEvents flush];
  [OHHTTPStubs removeAllStubs];
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  // wait 1 seconds just to kick the run loop so that flushes can be processed
  // before starting next test.
  [blocker waitWithTimeout:1];
}

- (void)testActivate {
  // default to disabling timer based flushes so that long tests
  // don't get more flushes than explicitly expecting.
  [FBSDKAppEvents singleton].disableTimer = YES;
  NSString *appID = self.testAppID;
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  FBSDKTestBlocker *blocker2 = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block int activiesEndpointCalledCount = 0;

  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    NSString *const activitiesPath = [NSString stringWithFormat:@"%@/activities", appID];
    if ([request.URL.path hasSuffix:activitiesPath]) {
      NSDictionary *params = [FBSDKUtility dictionaryWithQueryString:request.URL.query];
      if (activiesEndpointCalledCount == 0) {
        // make sure install ping is first.
        XCTAssertEqualObjects(@"MOBILE_APP_INSTALL", params[@"event"]);
        [blocker signal];
      } else {
        NSString *body = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
        XCTAssertTrue([body rangeOfString:@"fb_mobile_activate_app"].location != NSNotFound);
        [blocker2 signal];
      }
      activiesEndpointCalledCount++;
    }
    // always return NO because we don't actually want to stub a http response, only
    // to intercept and verify request to fufill the expectation.
    return NO;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    return [OHHTTPStubsResponse responseWithData:[NSData data]
                                      statusCode:200
                                         headers:nil];
  }];

  // clear out all caches.
  [self clearUserDefaults];
  [FBSDKAppEventsUtility clearLibraryFiles];

  // call activate and verify publish install is called.
  [FBSDKAppEvents activateApp];
  XCTAssertTrue([blocker waitWithTimeout:8], @"did not get install ping");
  // activate would also queue up an activate event but that should not be flushed yet.
  XCTAssertEqual(1, activiesEndpointCalledCount, @"activities endpoint called more than once, maybe there was a premature flush?");

  // now flush
  [FBSDKAppEvents flush];
  XCTAssertTrue([blocker2 waitWithTimeout:8], @"did not get activate flush");
}

// same as below but inject no minimum time for considering new sessions in timespent
- (void)testDeactivationsMultipleSessions {
  // default to disabling timer based flushes so that long tests
  // don't get more flushes than explicitly expecting.
  [FBSDKAppEvents singleton].disableTimer = YES;
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block NSUInteger activiesEndpointCalledForActivateCount = 0;
  __block NSUInteger activiesEndpointCalledForDeactivateCount = 0;
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    NSString *const activitiesPath = [NSString stringWithFormat:@"%@/activities", self.testAppID];
    if ([request.URL.path hasSuffix:activitiesPath]) {
      NSString *body = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
      activiesEndpointCalledForDeactivateCount = [body countOfSubstring:@"fb_mobile_deactivate_app"];
      activiesEndpointCalledForActivateCount = [body countOfSubstring:@"fb_mobile_activate_app"];
      [blocker signal];
    }
    // always return NO because we don't actually want to stub a http response, only
    // to intercept and verify request to fufill the expectation.
    return NO;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    return [OHHTTPStubsResponse responseWithData:[NSData data]
                                      statusCode:200
                                         headers:nil];
  }];
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  // send a termination notification so that this test starts from a clean slate;
  // otherwise the preceding activate test will have already triggered the timespent processoing
  // which will skip the first activate.
  [notificationCenter postNotificationName:UIApplicationWillTerminateNotification object:nil];
  // make sure we remove any time spent persistence.
  [FBSDKAppEventsUtility clearLibraryFiles];
  // remove min time for considering deactivations (normally 60 seconds)
  [FBSDKTimeSpentData singleton].numSecondsIdleToBeNewSession = -1;

  [FBSDKAppEvents activateApp];
  [notificationCenter postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
  [notificationCenter postNotificationName:UIApplicationWillResignActiveNotification object:nil];
  [FBSDKAppEvents activateApp];
  [notificationCenter postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
  [notificationCenter postNotificationName:UIApplicationWillTerminateNotification object:nil];
  [FBSDKAppEvents activateApp];
  [notificationCenter postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
  [FBSDKAppEvents flush];

  XCTAssertTrue([blocker waitWithTimeout:30], @"did not get expectedflushes");
  XCTAssertEqual(3, activiesEndpointCalledForActivateCount);
  XCTAssertEqual(2, activiesEndpointCalledForDeactivateCount);
  [FBSDKTimeSpentData singleton].numSecondsIdleToBeNewSession = 60;
}

- (void)testDeactivationsSingleSession {
  // default to disabling timer based flushes so that long tests
  // don't get more flushes than explicitly expecting.
  [FBSDKAppEvents singleton].disableTimer = YES;
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block NSUInteger activiesEndpointCalledForActivateCount = 0;
  __block NSUInteger activiesEndpointCalledForDeactivateCount = 0;
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    NSString *const activitiesPath = [NSString stringWithFormat:@"%@/activities", self.testAppID];
    if ([request.URL.path hasSuffix:activitiesPath]) {
      NSString *body = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
      activiesEndpointCalledForDeactivateCount = [body countOfSubstring:@"fb_mobile_deactivate_app"];
      activiesEndpointCalledForActivateCount = [body countOfSubstring:@"fb_mobile_activate_app"];
      [blocker signal];
    }
    // always return NO because we don't actually want to stub a http response, only
    // to intercept and verify request to fufill the expectation.
    return NO;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    return [OHHTTPStubsResponse responseWithData:[NSData data]
                                      statusCode:200
                                         headers:nil];
  }];
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  // send a termination notification so that this test starts from a clean slate;
  // otherwise the preceding activate test will have already triggered the timespent processoing
  // which will skip the first activate.
  [notificationCenter postNotificationName:UIApplicationWillTerminateNotification object:nil];
  // make sure we remove any time spent persistence.
  [FBSDKAppEventsUtility clearLibraryFiles];

  [FBSDKAppEvents activateApp];
  [notificationCenter postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
  [notificationCenter postNotificationName:UIApplicationWillResignActiveNotification object:nil];
  [FBSDKAppEvents activateApp];
  [notificationCenter postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
  [notificationCenter postNotificationName:UIApplicationWillTerminateNotification object:nil];
  [FBSDKAppEvents activateApp];
  [notificationCenter postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
  [FBSDKAppEvents flush];

  XCTAssertTrue([blocker waitWithTimeout:5], @"did not get expectedflushes");
  XCTAssertEqual(1, activiesEndpointCalledForActivateCount);
  XCTAssertEqual(0, activiesEndpointCalledForDeactivateCount);
}

// test to verify flushing behavior when there are "session" changes.
- (void)testLogEventsBetweenAppAndUser {
  // default to disabling timer based flushes so that long tests
  // don't get more flushes than explicitly expecting.
  [FBSDKAppEvents singleton].disableTimer = YES;
  NSString *appID = self.testAppID;
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block int activiesEndpointCalledForUserCount = 0;
  __block int activiesEndpointCalledWithoutUserCount = 0;

  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    NSString *const activitiesPath = [NSString stringWithFormat:@"%@/activities", appID];
    if ([request.URL.path hasSuffix:activitiesPath]) {
      NSDictionary *params = [FBSDKUtility dictionaryWithQueryString:request.URL.query];
      if (params[@"access_token"]) {
        activiesEndpointCalledForUserCount++;
      } else {
        activiesEndpointCalledWithoutUserCount++;
      }

      if (activiesEndpointCalledForUserCount + activiesEndpointCalledWithoutUserCount == 2){
        [blocker signal];
      }
    }
    // always return NO because we don't actually want to stub a http response, only
    // to intercept and verify request to fufill the expectation.
    return NO;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    return [OHHTTPStubsResponse responseWithData:[NSData data]
                                      statusCode:200
                                         headers:nil];
  }];

  // this should queue up one event.
  [FBSDKAppEvents logEvent:@"event-without-user"];

  FBSDKAccessToken *token = [self getTokenWithPermissions:nil];
  [FBSDKAccessToken setCurrentAccessToken:token];

  // this should trigger a session change flush.
  [FBSDKAppEvents logEvent:@"event-with-user"];


  [FBSDKAccessToken setCurrentAccessToken:nil];
  // this should still just queue up another event for that user's token.
  [FBSDKAppEvents logEvent:@"event-with-user" valueToSum:nil parameters:nil accessToken:token];

  // now this should trigger a flush of the user's events, and leave this event queued.
  [FBSDKAppEvents logEvent:@"event-without-user"];

  XCTAssertTrue([blocker waitWithTimeout:16], @"did not get automatic flushes");
  XCTAssertEqual(1,activiesEndpointCalledForUserCount, @"more than one log request made with user token");
  XCTAssertEqual(1,activiesEndpointCalledWithoutUserCount, @"more than one log request made without user token");
  [FBSDKAppEvents flush];
}

// similar to above but with explicit flushing.
- (void)testLogEventsBetweenAppAndUserExplicitFlushing {
  // default to disabling timer based flushes so that long tests
  // don't get more flushes than explicitly expecting.
  [FBSDKAppEvents singleton].disableTimer = YES;
  NSString *appID = self.testAppID;
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block int activiesEndpointCalledForUserCount = 0;
  __block int activiesEndpointCalledWithoutUserCount = 0;

  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    NSString *const activitiesPath = [NSString stringWithFormat:@"%@/activities", appID];
    if ([request.URL.path hasSuffix:activitiesPath]) {
      NSDictionary *params = [FBSDKUtility dictionaryWithQueryString:request.URL.query];
      if (params[@"access_token"]) {
        activiesEndpointCalledForUserCount++;
      } else {
        activiesEndpointCalledWithoutUserCount++;
      }

      if (activiesEndpointCalledForUserCount + activiesEndpointCalledWithoutUserCount == 2){
        [blocker signal];
      }
    }
    // always return NO because we don't actually want to stub a http response, only
    // to intercept and verify request to fufill the expectation.
    return NO;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    return [OHHTTPStubsResponse responseWithData:[NSData data]
                                      statusCode:200
                                         headers:nil];
  }];

  [FBSDKAppEvents setFlushBehavior:FBSDKAppEventsFlushBehaviorExplicitOnly];
  FBSDKAccessToken *token = [self getTokenWithPermissions:nil];

  // log events with and without token interleaved, which would normally
  // cause flushes but should simply be retained now.
  [FBSDKAppEvents logEvent:@"event-without-user"];
  [FBSDKAppEvents logEvent:@"event-with-user" valueToSum:nil parameters:nil accessToken:token];
  [FBSDKAppEvents logEvent:@"event-without-user"];
  [FBSDKAppEvents logEvent:@"event-with-user" valueToSum:nil parameters:nil accessToken:token];
  [FBSDKAppEvents logEvent:@"event-without-user"];
  [FBSDKAppEvents logEvent:@"event-with-user" valueToSum:nil parameters:nil accessToken:token];
  [FBSDKAppEvents logEvent:@"event-without-user"];

  // now flush the last one (no user)
  [FBSDKAppEvents flush];

  // now log one more with user to flush
  [FBSDKAppEvents logEvent:@"event-with-user" valueToSum:nil parameters:nil accessToken:token];
  [FBSDKAppEvents flush];

  XCTAssertTrue([blocker waitWithTimeout:16], @"did not get both flushes");
  XCTAssertEqual(1,activiesEndpointCalledForUserCount, @"more than one log request made with user token");
  XCTAssertEqual(1,activiesEndpointCalledWithoutUserCount, @"more than one log request made without user token");
  [FBSDKAppEvents setFlushBehavior:FBSDKAppEventsFlushBehaviorAuto];
}

- (void)testLogEventsThreshold {
  // default to disabling timer based flushes so that long tests
  // don't get more flushes than explicitly expecting.
  [FBSDKAppEvents singleton].disableTimer = YES;
  NSString *appID = self.testAppID;
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block int activiesEndpointCalledCount = 0;

  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    NSString *const activitiesPath = [NSString stringWithFormat:@"%@/activities", appID];
    if ([request.URL.path hasSuffix:activitiesPath]) {
      ++activiesEndpointCalledCount;
      [blocker signal];
    }
    // always return NO because we don't actually want to stub a http response, only
    // to intercept and verify request to fufill the expectation.
    return NO;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    return [OHHTTPStubsResponse responseWithData:[NSData data]
                                      statusCode:200
                                         headers:nil];
  }];

  for (int i = 0; i < 101; i++) {
    [FBSDKAppEvents logEvent:@"event-to-test-threshold"];
  }
  XCTAssertTrue([blocker waitWithTimeout:8], @"did not get automatic flush");
  XCTAssertEqual(1,activiesEndpointCalledCount, @"more than one log request made");
}

// same as above but using explicit flush behavior and send more than the threshold
- (void)testLogEventsThresholdExplicit {
  // default to disabling timer based flushes so that long tests
  // don't get more flushes than explicitly expecting.
  [FBSDKAppEvents singleton].disableTimer = YES;
  NSString *appID = self.testAppID;
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block int activiesEndpointCalledCount = 0;

  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    NSString *const activitiesPath = [NSString stringWithFormat:@"%@/activities", appID];
    if ([request.URL.path hasSuffix:activitiesPath]) {
      ++activiesEndpointCalledCount;
      [blocker signal];
    }
    // always return NO because we don't actually want to stub a http response, only
    // to intercept and verify request to fufill the expectation.
    return NO;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    return [OHHTTPStubsResponse responseWithData:[NSData data]
                                      statusCode:200
                                         headers:nil];
  }];
  [FBSDKAppEvents setFlushBehavior:FBSDKAppEventsFlushBehaviorExplicitOnly];
  for (int i = 0; i < 300; i++) {
    [FBSDKAppEvents logEvent:@"event-to-test-threshold"];
  }
  // wait 20 seconds to also verify timer doesn't go off.
  NSLog(@"waiting 20 seconds to verify timer threshold...");
  XCTAssertFalse([blocker waitWithTimeout:20], @"premature flush");
  NSLog(@"...done. explicit flush");
  [FBSDKAppEvents flush];
  XCTAssertTrue([blocker waitWithTimeout:8], @"did not get flush");
  XCTAssertEqual(1,activiesEndpointCalledCount, @"more than one log request made");
  [FBSDKAppEvents setFlushBehavior:FBSDKAppEventsFlushBehaviorAuto];
}

- (void)testLogEventsTimerThreshold {
  // default to disabling timer based flushes so that long tests
  // don't get more flushes than explicitly expecting.
  [FBSDKAppEvents singleton].disableTimer = YES;
  NSString *appID = self.testAppID;
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block int activiesEndpointCalledCount = 0;

  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    NSString *const activitiesPath = [NSString stringWithFormat:@"%@/activities", appID];
    if ([request.URL.path hasSuffix:activitiesPath]) {
      ++activiesEndpointCalledCount;
      [blocker signal];
    }
    // always return NO because we don't actually want to stub a http response, only
    // to intercept and verify request to fufill the expectation.
    return NO;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    return [OHHTTPStubsResponse responseWithData:[NSData data]
                                      statusCode:200
                                         headers:nil];
  }];
  // just one under the event count threshold.
  for (int i = 0; i < 100; i++) {
    [FBSDKAppEvents logEvent:@"event-to-test-threshold"];
  }
  // timer should fire in 15 seconds.
  [FBSDKAppEvents singleton].disableTimer = NO;
  NSLog(@"waiting 25 seconds for automatic flush...");
  XCTAssertTrue([blocker waitWithTimeout:25], @"did not get automatic flush");
  XCTAssertEqual(1,activiesEndpointCalledCount, @"more than one log request made");
}

// send logging events from different queues.
- (void)testThreadsLogging {
  // default to disabling timer based flushes so that long tests
  // don't get more flushes than explicitly expecting.
  [FBSDKAppEvents singleton].disableTimer = YES;
  NSString *appID = self.testAppID;
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block int activiesEndpointCalledCount = 0;

  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    NSString *const activitiesPath = [NSString stringWithFormat:@"%@/activities", appID];
    if ([request.URL.path hasSuffix:activitiesPath]) {
      if (++activiesEndpointCalledCount == 2) {
        [blocker signal];
      }
    }
    // always return NO because we don't actually want to stub a http response, only
    // to intercept and verify request to fufill the expectation.
    return NO;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    return [OHHTTPStubsResponse responseWithData:[NSData data]
                                      statusCode:200
                                         headers:nil];
  }];

  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  // 202 events will trigger two automatic flushes
  for (int i = 0; i < 202; i++) {
    dispatch_async(queue, ^{
      NSString *eventName = [NSString stringWithFormat:@"event-to-test-threshold-from-queue-%d", i];
      [FBSDKAppEvents logEvent:eventName];
    });
  }
  XCTAssertTrue([blocker waitWithTimeout:10], @"did not get automatic flushes");
  XCTAssertEqual(2,activiesEndpointCalledCount, @"more than two log request made");
}

- (void)testInitAppEventWorkerThread {
  NSString *appID = self.testAppID;
  FBSDKTestBlocker *blocker = [[FBSDKTestBlocker alloc] initWithExpectedSignalCount:1];
  __block int activiesEndpointCalledCount = 0;

  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    NSString *const activitiesPath = [NSString stringWithFormat:@"%@/activities", appID];
    if ([request.URL.path hasSuffix:activitiesPath]) {
      ++activiesEndpointCalledCount;
      [blocker signal];
    }
    // always return NO because we don't actually want to stub a http response, only
    // to intercept and verify request to fufill the expectation.
    return NO;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    return [OHHTTPStubsResponse responseWithData:[NSData data]
                                      statusCode:200
                                         headers:nil];
  }];

  // clear out all caches.
  [self clearUserDefaults];
  [FBSDKAppEventsUtility clearLibraryFiles];

  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
  // initiate singleton in a worker thread
  dispatch_async(queue,^{
    [FBSDKAppEvents singleton].disableTimer = NO;
  });
  // just one under the event count threshold.
  for (int i = 0; i < 100; i++) {
    [FBSDKAppEvents logEvent:@"event-to-test-threshold"];
  }
  XCTAssertTrue([blocker waitWithTimeout:25], @"did not get automatic flush");
  XCTAssertEqual(1,activiesEndpointCalledCount, @"more than one log request made");
}

@end
