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

#import <OCMock/OCMock.h>
#import "FBAppEventsIntegrationTests.h"
#import "Facebook.h"
#import "FBAppEvents+Internal.h"
#import "FBTestBlocker.h"
#import "FBUtility.h"
#import <objc/objc-runtime.h>

@interface FBAppEventsIntegrationTests() {
    id _mockFBUtility;
    Method _originalPublishInstall;
    Method _swizzledPublishInstall;

    Method _originalLogEvent;
    Method _swizzledLogEvent;
}
@end

static int publishInstallCount = 0;
static NSString *loggedEvent = nil;

@implementation FBAppEventsIntegrationTests

- (void)setUp {
    [super setUp];
    // Before every test, mock the FBUtility class to return a nil
    // advertiserID because the `[[ advertisingIdentifier] UUIDString]` call likes to hang.
    _mockFBUtility = [[OCMockObject mockForClass:[FBUtility class]] retain];
    [[[_mockFBUtility stub] andReturn:nil] advertiserID];
}

- (void)tearDown {
    [super tearDown];
    [_mockFBUtility release];
    _mockFBUtility = nil;
}

+ (void)publishInstallCounter:(NSString *)appID {
  publishInstallCount++;
}

+ (void)logEvent:(NSString *)eventName {
  [loggedEvent release];
  loggedEvent = [eventName retain];
}

// Ensure session is not closed by a bogus app event log.
-(void) testSessionNotClosed {
    // *** COPY-PASTA README *** read this if you are copying tests for FBAppEvents!
    // Configure OCMock of FBAppEvents to expect handleActivitiesPostCompletion: instead of instanceFlush: because
    // 1. [OCMArg any] does not work for primitives
    //   (especially for methods that only take a primitive argument. Even the 2.2 update with ignoringNonObjectArgs does not work).
    // 2. We want to wait for the end of handleActivitiesPostCompletion to make sure other tests are started
    //  before the flush finishes (otherwise, there are logs "in-flight" that may block other tests' flush).
    id appEventsSingletonMock = [OCMockObject partialMockForObject:[FBAppEvents singleton]];
    [[appEventsSingletonMock expect] handleActivitiesPostCompletion:[OCMArg any]
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
                                                                  refreshDate:nil];
    FBSession *session = [[[FBSession alloc] initWithAppID:@"appid"
                                              permissions:nil
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:[FBSessionTokenCachingStrategy nullCacheInstance]] autorelease];
    [session openFromAccessTokenData:accessToken completionHandler:nil];
    
    STAssertTrue(session.isOpen, @"Unable to verify test, session should be open");
    
    [FBAppEvents logEvent:@"some_event" valueToSum:nil parameters:nil session:session];
    [FBAppEvents flush];
    
    [FBTestBlocker waitForVerifiedMock:appEventsSingletonMock delay:5.0];
  
    [appEventsSingletonMock stopMocking];
}

-(void) testUpdateParametersWithEventUsageLimitsAndBundleInfo {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
  
    // default should set 1 for the app setting.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"com.facebook.sdk:FBAppEventsLimitEventUsage"];
    [FBUtility updateParametersWithEventUsageLimitsAndBundleInfo:parameters];
    STAssertTrue([parameters[@"application_tracking_enabled"] isEqualToString:@"1"], @"app tracking should default to 1");
  
    // when limited, app tracking is 0.
    [parameters removeAllObjects];
    FBSettings.limitEventAndDataUsage = YES;
    [FBUtility updateParametersWithEventUsageLimitsAndBundleInfo:parameters];
    STAssertTrue([parameters[@"application_tracking_enabled"] isEqualToString:@"0"], @"app tracking should be 0 when event usage is limited");
  
    // when explicitly unlimited, app tracking is 1.
    [parameters removeAllObjects];
    FBSettings.limitEventAndDataUsage = NO;
    [FBUtility updateParametersWithEventUsageLimitsAndBundleInfo:parameters];
    STAssertTrue([parameters[@"application_tracking_enabled"] isEqualToString:@"1"], @"app tracking should be 1 when event usage is explicitly unlimited");
}

-(void) testActivateApp {
    // swizzle out the underlying calls.
    _originalPublishInstall = class_getClassMethod([FBSettings class], @selector(publishInstall:));
    _swizzledPublishInstall = class_getClassMethod([self class], @selector(publishInstallCounter:));
    method_exchangeImplementations(_originalPublishInstall, _swizzledPublishInstall);

    _originalLogEvent = class_getClassMethod([FBAppEvents class], @selector(logEvent:));
    _swizzledLogEvent = class_getClassMethod([self class], @selector(logEvent:));
    method_exchangeImplementations(_originalLogEvent, _swizzledLogEvent);
  
    publishInstallCount = 0;
    loggedEvent = nil;
  
    [FBSettings setDefaultAppID:@"appid"];
    [FBAppEvents activateApp];
    STAssertTrue(publishInstallCount == 1, @"publishInstall was not triggered by activateApp");
    STAssertTrue([@"fb_mobile_activate_app" isEqualToString:loggedEvent], @"activate app event not logged by activateApp call!");
  
    [loggedEvent release];
    loggedEvent = nil;
  
    method_exchangeImplementations(_swizzledPublishInstall, _originalPublishInstall);
    _originalPublishInstall = nil;
    _swizzledPublishInstall = nil;
  
    method_exchangeImplementations(_swizzledLogEvent, _originalLogEvent);
    _originalLogEvent = nil;
    _swizzledLogEvent = nil;
}

@end
