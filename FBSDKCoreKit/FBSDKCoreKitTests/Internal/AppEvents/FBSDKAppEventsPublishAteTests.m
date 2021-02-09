//
// FBSDKAppEventsPublishAteTests.m
// FBSDKCoreKitTests
//
// Created by joesusnick on 2/8/21.
// Copyright © 2021 Facebook. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "FBSDKAppEventsAtePublisher.h"
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
@end

@interface FBSDKAppEventsPublishAteTests : FBSDKTestCase

@end

@implementation FBSDKAppEventsPublishAteTests

- (void)setUp
{
  [super setUp];

  [self stubAllocatingGraphRequestConnection];
}

- (void)testDefaultAppEventsAtePublisher
{
  [self stubAppID:self.name];

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
