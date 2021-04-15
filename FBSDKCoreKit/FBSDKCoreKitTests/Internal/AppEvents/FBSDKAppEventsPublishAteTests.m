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

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

@import TestTools;

#import "FBSDKAppEventsAtePublisher.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKTestCase.h"
#import "UserDefaultsSpy.h"

// TODO: move to swift
@interface FakeAtePublisher : NSObject <FBSDKAtePublishing>
@property (nonatomic, assign) BOOL publishAteWasCalled;
@end

@implementation FakeAtePublisher

- (instancetype)init
{
  if ((self = [super init])) {
    _publishAteWasCalled = NO;
  }
  return self;
}

- (void)publishATE
{
  self.publishAteWasCalled = YES;
}

@end

@interface FBSDKAppEvents (Testing)
@property (nonatomic, strong) id<FBSDKAtePublishing> atePublisher;
- (instancetype)initWithFlushBehavior:(FBSDKAppEventsFlushBehavior)flushBehavior
                 flushPeriodInSeconds:(int)flushPeriodInSeconds
                               userID:(NSString *)userID
                         atePublisher:(id<FBSDKAtePublishing>)atePublisher;
- (void)publishATE;
+ (void)setSettings:(id<FBSDKSettings>)settings;
@end

@interface FBSDKAppEventsPublishAteTests : FBSDKTestCase
@property (nonatomic, strong) id<FBSDKSettings> settings;
@end

@implementation FBSDKAppEventsPublishAteTests

- (void)setUp
{
  [super setUp];

  [self stubAllocatingGraphRequestConnection];
  _settings = [TestSettings new];
  [FBSDKAppEvents setSettings:_settings];
}

- (void)testDefaultAppEventsAtePublisher
{
  _settings.appID = self.name;

  FBSDKAppEvents *appEvents = (FBSDKAppEvents *)[(NSObject *)[FBSDKAppEvents alloc] init];

  FBSDKAppEventsAtePublisher *publisher = appEvents.atePublisher;

  XCTAssertNotNil(publisher, "App events should be provided with an ATE publisher on initialization");
  XCTAssertEqualObjects(
    publisher.appIdentifier,
    self.name,
    "The ATE publisher should be created with the current app identifier"
  );
}

- (void)testPublishingAteWithoutPublisher
{
  FBSDKAppEvents *appEvents = [[FBSDKAppEvents alloc] initWithFlushBehavior:FBSDKAppEventsFlushBehaviorExplicitOnly
                                                       flushPeriodInSeconds:0
                                                                     userID:@"1"
                                                               atePublisher:nil];
  // checking that there is no crash
  [appEvents publishATE];
}

- (void)testPublishingAteUsesPublisherOnlyOnce
{
  FakeAtePublisher *publisher = [FakeAtePublisher new];
  FBSDKAppEvents *appEvents = [[FBSDKAppEvents alloc] initWithFlushBehavior:FBSDKAppEventsFlushBehaviorExplicitOnly
                                                       flushPeriodInSeconds:0
                                                                     userID:@"1"
                                                               atePublisher:publisher];
  [appEvents publishATE];

  XCTAssertTrue(publisher.publishAteWasCalled, "App events should use the provided ATE publisher");

  // Reset the spy
  publisher.publishAteWasCalled = NO;

  [appEvents publishATE];
  XCTAssertFalse(
    publisher.publishAteWasCalled,
    "Should not invoke the ate publisher more than once"
  );
}

@end
