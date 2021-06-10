// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web ser`vices and APIs provided by Facebook.
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

#import "FBSDKTestCase.h"

#import <OCMock/OCMock.h>

// For mocking ASIdentifier
#import <AdSupport/AdSupport.h>

#import "FBSDKAppEvents.h"
#import "FBSDKAppEventsConfigurationManager.h"
#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKGraphRequestPiggybackManager.h"

@interface FBSDKAppEvents (Testing)
+ (FBSDKAppEvents *)singleton;
- (instancetype)initWithFlushBehavior:(FBSDKAppEventsFlushBehavior)flushBehavior
                 flushPeriodInSeconds:(int)flushPeriodInSeconds;
@end

@interface FBSDKAppEventsConfigurationManager (Testing)
+ (void)loadAppEventsConfigurationWithBlock:(FBSDKAppEventsConfigurationManagerBlock)block;
@end

@implementation FBSDKTestCase

- (void)setUp
{
  [super setUp];

  _appID = @"appid";

  // Using timers with async unit tests is a recipe for unexpected behavior.
  // We need to create the UtilityMock and stub the timer method before we do
  // anything else since other partial mocks setup below this will create a timer
  [self setUpUtilityClassMock];
  [self stubStartGCDTimerWithInterval];
  [self setUpSettingsMock];
  [self setUpAppEventsUtilityMock];
  [self setUpInternalUtilityMock];
  [self setUpGraphRequestConnectionClassMock];
  [self setUpSharedApplicationMock];
  [self setUpTransitionCoordinatorMock];
  [self setUpBridgeApiClassMock];
  [self setUpASIdentifierClassMock];
  [self setUpAppEventsMock];
}

- (void)tearDown
{
  [super tearDown];

  [_appEventsMock stopMocking];
  _appEventsMock = nil;

  [_appEventsUtilityClassMock stopMocking];
  _appEventsUtilityClassMock = nil;

  [_settingsClassMock stopMocking];
  _settingsClassMock = nil;

  [_graphRequestConnectionClassMock stopMocking];
  _graphRequestConnectionClassMock = nil;

  [_sharedApplicationMock stopMocking];
  _sharedApplicationMock = nil;

  [_transitionCoordinatorMock stopMocking];
  _transitionCoordinatorMock = nil;

  [_bridgeApiResponseClassMock stopMocking];
  _bridgeApiResponseClassMock = nil;

  [_utilityClassMock stopMocking];
  _utilityClassMock = nil;

  [_asIdentifierManagerClassMock stopMocking];
  _asIdentifierManagerClassMock = nil;
}

- (void)setUpSettingsMock
{
  _settingsClassMock = OCMStrictClassMock(FBSDKSettings.class);
}

- (void)setUpAppEventsMock
{
  if (self.shouldAppEventsMockBePartial) {
    // Partial mocks will try and fetch various configurations upon creation.
    // This is ham-fisted but preempts accidental network traffic.
    // We can get rid of this when we refactor to have an injectable dependency
    // for creating graph requests.
    [self stubAllocatingGraphRequestConnection];

    // Since the `init` method is marked unavailable but just as a measure to prevent creating multiple
    // instances and enforce the singleton pattern, we will circumvent that by casting to a plain `NSObject`
    // after `alloc` in order to call `init`.
    _appEventsMock = OCMPartialMock(
      [[FBSDKAppEvents alloc] initWithFlushBehavior:FBSDKAppEventsFlushBehaviorExplicitOnly
                               flushPeriodInSeconds:0]
    );
  } else {
    _appEventsMock = OCMClassMock([FBSDKAppEvents class]);
  }

  // Since numerous areas in FBSDK can end up calling `[FBSDKAppEvents singleton]`,
  // we will stub the singleton accessor out for our mock instance.
  OCMStub([_appEventsMock singleton]).andReturn(_appEventsMock);
}

- (void)setUpAppEventsUtilityMock
{
  _appEventsUtilityClassMock = OCMStrictClassMock(FBSDKAppEventsUtility.class);
}

- (void)setUpInternalUtilityMock
{
  self.internalUtilityClassMock = OCMStrictClassMock(FBSDKInternalUtility.class);
}

- (void)setUpGraphRequestConnectionClassMock
{
  self.graphRequestConnectionClassMock = OCMClassMock(FBSDKGraphRequestConnection.class);
}

- (void)setUpSharedApplicationMock
{
  self.sharedApplicationMock = OCMClassMock(UIApplication.class);
  OCMStub(ClassMethod([_sharedApplicationMock sharedApplication])).andReturn(_sharedApplicationMock);
}

- (void)setUpTransitionCoordinatorMock
{
  self.transitionCoordinatorMock = [OCMockObject
                                    mockForProtocol:@protocol(UIViewControllerTransitionCoordinator)];
}

- (void)setUpBridgeApiClassMock
{
  _bridgeApiResponseClassMock = OCMClassMock(FBSDKBridgeAPIResponse.class);
}

- (void)setUpUtilityClassMock
{
  _utilityClassMock = OCMClassMock(FBSDKUtility.class);
}

- (void)setUpASIdentifierClassMock
{
  _asIdentifierManagerClassMock = OCMClassMock(ASIdentifierManager.class);
}

#pragma mark - Public Methods

- (void)stubAppEventsUtilityShouldDropAppEventWith:(BOOL)shouldDropEvent
{
  OCMStub(ClassMethod([_appEventsUtilityClassMock shouldDropAppEvent])).andReturn(shouldDropEvent);
}

- (void)stubAppEventsUtilityAdvertiserIDWith:(nullable NSString *)identifier
{
  OCMStub(ClassMethod([_appEventsUtilityClassMock shared])).andReturn(_appEventsUtilityClassMock);
  OCMStub([_appEventsUtilityClassMock advertiserID]).andReturn(identifier);
}

- (void)stubAllocatingGraphRequestConnection
{
  OCMStub(ClassMethod([_graphRequestConnectionClassMock alloc])).andReturn(_graphRequestConnectionClassMock);
}

- (void)stubOpenURLWith:(BOOL)openURL
{
  OCMStub([_sharedApplicationMock openURL:OCMArg.any]).andReturn(openURL);
}

- (void)stubOpenUrlOptionsCompletionHandlerWithPerformCompletion:(BOOL)performCompletion
                                               completionSuccess:(BOOL)completionSuccess
{
  if (performCompletion) {
    OCMStub([_sharedApplicationMock openURL:OCMArg.any options:OCMArg.any completionHandler:([OCMArg invokeBlockWithArgs:@(completionSuccess), nil])]);
  } else {
    OCMStub([_sharedApplicationMock openURL:OCMArg.any options:OCMArg.any completionHandler:OCMArg.any]);
  }
}

- (void)stubAppUrlSchemeWith:(nullable NSString *)scheme
{
  OCMStub([self.internalUtilityClassMock appURLScheme]).andReturn(scheme);
}

- (void)stubStartGCDTimerWithInterval
{
  // Note: the '5' is arbitrary and ignored but needs to be there for compilation.
  OCMStub(ClassMethod([self.utilityClassMock startGCDTimerWithInterval:5 block:OCMArg.any]));
}

- (void)stubSharedAsIdentifierManagerWithAsIdentifierManager:(ASIdentifierManager *)identifierManager
{
  OCMStub([self.asIdentifierManagerClassMock sharedManager]).andReturn(identifierManager);
}

- (void)stubAdvertisingIdentifierWithIdentifier:(NSUUID *)uuid
{
  OCMStub([self.asIdentifierManagerClassMock advertisingIdentifier]).andReturn(uuid);
}

@end
