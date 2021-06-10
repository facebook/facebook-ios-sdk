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

#import <XCTest/XCTest.h>

@import TestTools;

#import "FBSDKAppEvents+AppEventsConfiguring.h"
#import "FBSDKAppEventsAtePublisher.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "UserDefaultsSpy.h"

@interface FBSDKAppEvents (Testing)
@property (nullable, nonatomic) id<FBSDKAtePublishing> atePublisher;
- (instancetype)initWithFlushBehavior:(FBSDKAppEventsFlushBehavior)flushBehavior
                 flushPeriodInSeconds:(int)flushPeriodInSeconds;
- (void)publishATE;
+ (void)setSettings:(id<FBSDKSettings>)settings;
@end

@interface FBSDKAppEventsPublishAteTests : XCTestCase
@property (nonatomic, strong) id<FBSDKSettings> settings;
@end

@implementation FBSDKAppEventsPublishAteTests

- (void)setUp
{
  [super setUp];

  _settings = [TestSettings new];
  [FBSDKAppEvents setSettings:_settings];
}

- (void)testDefaultAppEventsAtePublisher
{
  _settings.appID = self.name;

  FBSDKAppEvents *appEvents = (FBSDKAppEvents *)[(NSObject *)[FBSDKAppEvents alloc] init];

  XCTAssertNil(
    appEvents.atePublisher,
    "App events should be provided with an ATE publisher on initialization"
  );
}

- (void)testPublishingAteWithoutPublisher
{
  FBSDKAppEvents *appEvents = [[FBSDKAppEvents alloc]
                               initWithFlushBehavior:FBSDKAppEventsFlushBehaviorExplicitOnly
                               flushPeriodInSeconds:0];
  // checking that there is no crash
  [appEvents publishATE];
}

- (void)testPublishingAteAgainAfterSettingAppID
{
  TestAtePublisher *publisher = [TestAtePublisher new];
  TestAtePublisherFactory *factory = [TestAtePublisherFactory new];
  factory.stubbedPublisher = publisher;
  FBSDKAppEvents *appEvents = [[FBSDKAppEvents alloc]
                               initWithFlushBehavior:FBSDKAppEventsFlushBehaviorExplicitOnly
                               flushPeriodInSeconds:0];
  [appEvents publishATE];
  XCTAssertFalse(
    publisher.publishAteWasCalled,
    "App events Should not invoke the ATE publisher when there is not App ID"
  );

  _settings.appID = self.name;
  [appEvents configureWithGateKeeperManager:TestGateKeeperManager.class
             appEventsConfigurationProvider:TestAppEventsConfigurationProvider.class
                serverConfigurationProvider:TestServerConfigurationProvider.class
                       graphRequestProvider:[TestGraphRequestFactory new]
                             featureChecker:[TestFeatureManager new]
                                      store:[UserDefaultsSpy new]
                                     logger:TestLogger.class
                                   settings:_settings
                            paymentObserver:[TestPaymentObserver new]
                   timeSpentRecorderFactory:[TestTimeSpentRecorderFactory new]
                        appEventsStateStore:[TestAppEventsStateStore new]
        eventDeactivationParameterProcessor:[TestAppEventsParameterProcessor new]
    restrictiveDataFilterParameterProcessor:[TestAppEventsParameterProcessor new]
                        atePublisherFactory:factory
                     appEventsStateProvider:[TestAppEventsStateProvider new]
                                   swizzler:TestSwizzler.class];

  [appEvents publishATE];
  XCTAssertTrue(
    publisher.publishAteWasCalled,
    "App events should use the ATE publisher created by the configure method"
  );
}

@end
