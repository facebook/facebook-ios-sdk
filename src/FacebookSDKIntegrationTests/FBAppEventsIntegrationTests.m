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

#import <objc/runtime.h>

#import <OCMock/OCMock.h>

#import "FBAppEvents+Internal.h"
#import "FBIntegrationTests.h"
#import "FBSettings+Internal.h"
#import "FBTestBlocker.h"
#import "FBUtility.h"
#import "Facebook.h"

static int publishInstallCount = 0;
static NSString *loggedEvent = nil;
static NSDictionary *loggedParameter = nil;
static id gMockAppEventsSingleton = nil;

// In order to test behavior on the FBAppEvents singleton,
// we setup a static mock object that is available to each
// test; i.e, if you need to perform OCMock expect/verify,
// apply them to `gMockAppEventsSingleton`
@implementation FBAppEvents(FBAppEventsIntegrationTests)

+(FBAppEvents *)singleton {
    return gMockAppEventsSingleton;
}

@end

@interface FBAppEventsIntegrationTests : FBIntegrationTests
@end

@implementation FBAppEventsIntegrationTests

- (void)setUp {
    [super setUp];
    gMockAppEventsSingleton = [[OCMockObject partialMockForObject:[[[FBAppEvents alloc] init] autorelease]] retain];
}

- (void)tearDown {
    [super tearDown];
    [gMockAppEventsSingleton release];
    gMockAppEventsSingleton = nil;
}

- (void)publishInstallCounter:(NSString *)appID {
  publishInstallCount++;
}

- (void)logEvent:(NSString *)eventName parameters:(NSDictionary *)parameters {
    [loggedEvent release];
    loggedEvent = [eventName retain];
    [loggedParameter release];
    loggedParameter = [[NSDictionary alloc] initWithDictionary:parameters copyItems:YES];
}

// Ensure session is not closed by a bogus app event log.
- (void)testSessionNotClosed {
    [[gMockAppEventsSingleton expect] handleActivitiesPostCompletion:[OCMArg any]
                                                        loggingEntry:[OCMArg any]
                                                             session:[OCMArg checkWithBlock:^BOOL(id obj) {
                                                                        FBSession *session = (FBSession *)obj;
                                                                        NSLog(@"verifying session:%@", session);
                                                                        //session should remain open.
                                                                        return session.isOpen;
                                                                    }]
     ];
    
    FBAccessTokenData *accessToken = [FBAccessTokenData createTokenFromString:@"bogustoken"
                                                                  permissions:nil
                                                               expirationDate:nil
                                                                    loginType:FBSessionLoginTypeFacebookApplication
                                                                  refreshDate:nil
                                                       permissionsRefreshDate:nil
                                                                        appID:@"appid"];
    FBSession *session = [[[FBSession alloc] initWithAppID:@"appid"
                                              permissions:nil
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:[FBSessionTokenCachingStrategy nullCacheInstance]] autorelease];
    [session openFromAccessTokenData:accessToken completionHandler:nil];
    
    XCTAssertTrue(session.isOpen, @"Unable to verify test, session should be open");
    
    [FBAppEvents logEvent:@"some_event" valueToSum:nil parameters:nil session:session];
    [FBAppEvents flush];
    
    [FBTestBlocker waitForVerifiedMock:gMockAppEventsSingleton delay:5.0];
}

- (void)testUpdateParametersWithEventUsageLimitsAndBundleInfo {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
  
    // default should set 1 for the app setting.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"com.facebook.sdk:FBAppEventsLimitEventUsage"];
    parameters = [FBUtility activityParametersDictionaryForEvent:@"event" implicitEventsOnly:NO shouldAccessAdvertisingID:YES];
    XCTAssertTrue([parameters[@"application_tracking_enabled"] isEqualToString:@"1"], @"app tracking should default to 1");
  
    // when limited, app tracking is 0.
    [parameters removeAllObjects];
    FBSettings.limitEventAndDataUsage = YES;
    parameters = [FBUtility activityParametersDictionaryForEvent:@"event" implicitEventsOnly:NO shouldAccessAdvertisingID:YES];
    XCTAssertTrue([parameters[@"application_tracking_enabled"] isEqualToString:@"0"], @"app tracking should be 0 when event usage is limited");
  
    // when explicitly unlimited, app tracking is 1.
    [parameters removeAllObjects];
    FBSettings.limitEventAndDataUsage = NO;
    parameters = [FBUtility activityParametersDictionaryForEvent:@"event" implicitEventsOnly:NO shouldAccessAdvertisingID:YES];
    XCTAssertTrue([parameters[@"application_tracking_enabled"] isEqualToString:@"1"], @"app tracking should be 1 when event usage is explicitly unlimited");
}

- (void)testActivateApp {
    id mockSettings = [OCMockObject mockForClass:[FBSettings class]];
    [[[mockSettings stub] andCall:@selector(publishInstallCounter:) onObject:self] publishInstall:[OCMArg any]];

    id mockFBAppEvents = [OCMockObject mockForClass:[FBAppEvents class]];
    [[[mockFBAppEvents stub] andCall:@selector(logEvent:parameters:) onObject:self] logEvent:[OCMArg any] parameters:[OCMArg any]];

    publishInstallCount = 0;
    loggedEvent = nil;
    NSString *originalAppId = [FBSettings defaultAppID];
    [FBSettings setDefaultAppID:@"appid"];
    [FBAppEvents activateApp];
    [FBSettings setDefaultAppID:originalAppId];

    XCTAssertTrue(publishInstallCount == 1, @"publishInstall was not triggered by activateApp");
    XCTAssertTrue([@"fb_mobile_activate_app" isEqualToString:loggedEvent], @"activate app event not logged by activateApp call!");
    XCTAssertNotNil(loggedParameter[@"fb_mobile_launch_source"], @"activate app event not logged with source");
    [loggedEvent release];
    loggedEvent = nil;
    [loggedParameter release];
    loggedParameter = nil;

    [mockSettings stopMocking];
    [mockFBAppEvents stopMocking];
}

@end
