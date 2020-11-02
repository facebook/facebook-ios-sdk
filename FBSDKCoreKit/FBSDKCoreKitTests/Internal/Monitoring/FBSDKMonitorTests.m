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

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKTestCase.h"
#import "FakeMonitorStore.h"
#import "TestMonitorEntry.h"

@interface FBSDKMonitor (Testing)

+ (NSMutableArray<id<FBSDKMonitorEntry>> *)entries;
+ (void)setStore:(FBSDKMonitorStore *)store;
+ (void)disable;
+ (void)flush;
+ (void)applicationMovingFromActiveStateOrTerminating;

@end

@interface FBSDKMonitorTests : FBSDKTestCase

@property (nonatomic) id<FBSDKMonitorEntry> entry;
@property (nonatomic) FakeMonitorStore *store;

@end

@implementation FBSDKMonitorTests
{
  int flushLimit;
  double flushInterval;
  id networkerMock;
  id notificationCenterMock;
  id timerMock;
}

- (void)setUp
{
  [super setUp];

  flushLimit = 100;
  flushInterval = 60;
  [FBSDKSettings setAppID:@"abc123"];
  self.entry = [TestMonitorEntry testEntry];
  self.store = [[FakeMonitorStore alloc] initWithFilename:@"foo"];
  [FBSDKMonitor setStore:self.store];
  networkerMock = OCMClassMock([FBSDKMonitorNetworker class]);
  notificationCenterMock = OCMClassMock([NSNotificationCenter class]);
  timerMock = OCMClassMock([NSTimer class]);

  [self stubAllocatingGraphRequestConnection];
}

- (void)tearDown
{
  [networkerMock stopMocking];
  [notificationCenterMock stopMocking];
  [timerMock stopMocking];
  [FBSDKMonitor flush];
  [FBSDKMonitor disable];
  [FBSDKMonitor setStore:nil];

  [super tearDown];
}

- (void)testRecordingWhenDisabled
{
  [FBSDKMonitor record:self.entry];

  XCTAssertEqual(
    FBSDKMonitor.entries.count,
    0,
    @"Should not record entries before monitor is enabled"
  );
}

- (void)testEnabling
{
  [FBSDKMonitor enable];

  [FBSDKMonitor record:self.entry];

  XCTAssertEqualObjects(
    FBSDKMonitor.entries,
    @[self.entry],
    @"Should record entries when monitor is enabled"
  );
}

- (void)testEnablingWhenEnabled
{
  OCMStub([notificationCenterMock defaultCenter]).andReturn(notificationCenterMock);

  [FBSDKMonitor enable];

  // Should register for notifications
  OCMVerify(
    [notificationCenterMock addObserver:[FBSDKMonitor class]
                               selector:@selector(applicationMovingFromActiveStateOrTerminating)
                                   name:[OCMArg any]
                                 object:NULL]
  );

  // Should not re-register for notifications if still enabled
  OCMReject(
    [notificationCenterMock addObserver:[FBSDKMonitor class]
                               selector:@selector(applicationMovingFromActiveStateOrTerminating)
                                   name:[OCMArg any]
                                 object:NULL]
  );

  [FBSDKMonitor enable];
}

- (void)testDisabling
{
  NSArray *entries = @[self.entry];
  [FBSDKMonitor enable];
  [FBSDKMonitor record:self.entry];
  [self.store persist:entries];
  self.store.persistWasCalled = false;

  // Should not invoke networker if monitor is disabled
  OCMStub([notificationCenterMock defaultCenter]).andReturn(notificationCenterMock);

  OCMReject([networkerMock sendEntries:entries]);

  [FBSDKMonitor disable];

  XCTAssertTrue(
    self.store.clearWasCalled,
    @"Disabling monitoring should clear the persistent store"
  );
  XCTAssertEqual(
    FBSDKMonitor.entries.count,
    0,
    @"Disabling monitoring should clear the locally stored entries"
  );

  OCMVerify([notificationCenterMock removeObserver:[FBSDKMonitor class]]);
}

- (void)testDisablingUnregistersNotifications
{
  [FBSDKMonitor enable];

  // Should not invoke networker if monitor is disabled
  OCMStub([notificationCenterMock defaultCenter]).andReturn(notificationCenterMock);

  [FBSDKMonitor disable];

  // Should unregister for notifications when disabling
  OCMVerify([notificationCenterMock removeObserver:[FBSDKMonitor class]]);
}

- (void)testDisablingWhenDisabled
{
  // Should not invoke networker if monitor is disabled
  OCMStub([notificationCenterMock defaultCenter]).andReturn(notificationCenterMock);

  // Should not unregister for notifications if already disabled
  OCMReject([notificationCenterMock removeObserver:[FBSDKMonitor class]]);

  [FBSDKMonitor disable];
}

- (void)testReDisabling
{
  [FBSDKMonitor enable];

  // Should not invoke networker if monitor is disabled
  OCMStub([notificationCenterMock defaultCenter]).andReturn(notificationCenterMock);

  [FBSDKMonitor disable];

  // Should unregister for notifications when disabling
  OCMVerify([notificationCenterMock removeObserver:[FBSDKMonitor class]]);

  // Should not unregister for notifications if already disabled
  OCMReject([notificationCenterMock removeObserver:[FBSDKMonitor class]]);

  [FBSDKMonitor disable];
}

// MARK: - Flushing Tests

- (void)testFlushing
{
  [FBSDKMonitor enable];
  [FBSDKMonitor record:self.entry];

  [FBSDKMonitor flush];

  XCTAssertEqual(
    FBSDKMonitor.entries.count,
    0,
    @"Flushing should clear all entries"
  );
}

- (void)testFlushingWithoutEntries
{
  OCMReject(ClassMethod([networkerMock sendEntries:[OCMArg any]]));

  [FBSDKMonitor flush];
}

- (void)testFlushingWithEntries
{
  id<FBSDKMonitorEntry> entry2 = [TestMonitorEntry testEntryWithName:@"entry2"];
  NSArray<id<FBSDKMonitorEntry>> *expectedEntries = @[self.entry, entry2];

  [FBSDKMonitor enable];
  [FBSDKMonitor record:self.entry];
  [FBSDKMonitor record:entry2];
  [FBSDKMonitor flush];

  OCMVerify(
    ClassMethod(
      [networkerMock sendEntries:[OCMArg checkWithBlock:^BOOL (id obj) {
        XCTAssertEqualObjects(obj, expectedEntries);
        return YES;
      }]]
    )
  );
}

- (void)testRecordingAtOneBelowFlushLimit
{
  [FBSDKMonitor enable];
  NSMutableArray<id<FBSDKMonitorEntry>> *expectedEntries = [NSMutableArray array];

  // Should not invoke networker if the threshold is not met
  OCMReject(ClassMethod([networkerMock sendEntries:[OCMArg any]]));

  for (int i = 0; i < flushLimit - 1; i++) {
    [expectedEntries addObject:[TestMonitorEntry testEntry]];
    [FBSDKMonitor record:[TestMonitorEntry testEntry]];
  }

  XCTAssertEqual(
    expectedEntries.count,
    flushLimit - 1,
    @"Sanity check failed"
  );
}

- (void)testRecordingAtFlushLimit
{
  [FBSDKMonitor enable];
  NSMutableArray<id<FBSDKMonitorEntry>> *expectedEntries = [NSMutableArray array];

  for (int i = 0; i < flushLimit; i++) {
    [expectedEntries addObject:[TestMonitorEntry testEntry]];
    [FBSDKMonitor record:[TestMonitorEntry testEntry]];
  }

  XCTAssertEqual(
    expectedEntries.count,
    flushLimit,
    @"Sanity check failed"
  );

  OCMVerify(
    ClassMethod(
      [networkerMock sendEntries:[OCMArg checkWithBlock:^BOOL (id obj) {
        XCTAssertEqual(
          [obj count],
          expectedEntries.count,
          @"Should send the correct number of entries when the flush limit is reached"
        );
        return YES;
      }]]
    )
  );
}

- (void)testRecordingPastFlushLimit
{
  [FBSDKMonitor enable];

  for (int i = 0; i < flushLimit; i++) {
    [FBSDKMonitor record:[TestMonitorEntry testEntry]];
  }

  XCTAssertEqual(
    FBSDKMonitor.entries.count,
    0,
    @"Should flush entries after reaching threshold"
  );

  [FBSDKMonitor record:self.entry];

  XCTAssertEqual(
    FBSDKMonitor.entries.count,
    1,
    @"Should continue to record entries after surpassing the flush limit"
  );
}

- (void)testEnablingStartsFlushTimer
{
  [FBSDKMonitor enable];
  [FBSDKMonitor record:self.entry];

  OCMVerify(
    ClassMethod(
      [timerMock scheduledTimerWithTimeInterval:flushInterval
                                         target:[FBSDKMonitor class]
                                       selector:@selector(flush)
                                       userInfo:nil
                                        repeats:YES]
    )
  );
  [timerMock stopMocking];
}

- (void)testDisablingInvalidatesFlushTimer
{
  OCMStub(
    ClassMethod(
      [timerMock scheduledTimerWithTimeInterval:flushInterval
                                         target:[FBSDKMonitor class]
                                       selector:@selector(flush)
                                       userInfo:nil
                                        repeats:YES]
    )
  ).andReturn(timerMock);

  [FBSDKMonitor enable];
  [FBSDKMonitor disable];

  OCMVerify([timerMock invalidate]);
}

// MARK: - Lifecycle Tests

- (void)testBackgroundingWhenEnabledWithNoLocalEntries
{
  [FBSDKMonitor enable];

  [NSNotificationCenter.defaultCenter
   postNotificationName:UIApplicationWillResignActiveNotification object:nil];

  XCTAssertFalse(
    self.store.persistWasCalled,
    @"Should not attempt to persist empty list of entries on backgrounding"
  );
}

- (void)testBackgroundingWhenEnabledWithLocalEntries
{
  [FBSDKMonitor enable];
  [FBSDKMonitor record:self.entry];

  [NSNotificationCenter.defaultCenter
   postNotificationName:UIApplicationWillResignActiveNotification object:nil];

  XCTAssertTrue(
    self.store.persistWasCalled,
    @"Should persist entries on backgrounding"
  );
}

- (void)testBackgroundingWhenDisabled
{
  [FBSDKMonitor record:self.entry];

  [NSNotificationCenter.defaultCenter
   postNotificationName:UIApplicationWillResignActiveNotification object:nil];

  XCTAssertFalse(
    self.store.persistWasCalled,
    @"Should not persist entries on backgrounding if the monitor is disabled"
  );
}

- (void)testTerminatingWhenEnabledWithNoLocalEntries
{
  [FBSDKMonitor enable];

  [NSNotificationCenter.defaultCenter
   postNotificationName:UIApplicationWillTerminateNotification object:nil];

  XCTAssertFalse(
    self.store.persistWasCalled,
    @"Should not attempt to persist empty list of entries on termination"
  );
}

- (void)testTerminatingWhenEnabledWithLocalEntries
{
  [FBSDKMonitor enable];
  [FBSDKMonitor record:self.entry];

  [NSNotificationCenter.defaultCenter
   postNotificationName:UIApplicationWillTerminateNotification object:nil];

  XCTAssertTrue(
    self.store.persistWasCalled,
    @"Should persist entries on termination"
  );
}

- (void)testTerminatingWhenDisabled
{
  // Technically this should do nothing but keeping it to catch bugs
  // if implementation details change
  [FBSDKMonitor record:self.entry];

  [NSNotificationCenter.defaultCenter
   postNotificationName:UIApplicationWillTerminateNotification object:nil];

  XCTAssertFalse(
    self.store.persistWasCalled,
    @"Should not persist entries on backgrounding if the monitor is disabled"
  );
}

- (void)testForegroundingWhenEnabledWithNoLocalEntriesNoPersistedEntries
{
  // Should not invoke networker if no entries are retrieved
  OCMReject(ClassMethod([networkerMock sendEntries:[OCMArg any]]));

  [FBSDKMonitor enable];

  [NSNotificationCenter.defaultCenter
   postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];

  XCTAssertTrue(
    self.store.retrieveEntriesWasCalled,
    @"Should attempt to retrieve entries on foregrounding"
  );
  XCTAssertEqual(
    FBSDKMonitor.entries.count,
    0,
    @"Should set entries to the retrieved empty array"
  );
}

- (void)testForegroundingWhenEnabledWithLocalEntriesNoPersistedEntries
{
  NSArray<id<FBSDKMonitorEntry>> *entries = @[self.entry];
  [FBSDKMonitor enable];
  [FBSDKMonitor record:self.entry];

  [NSNotificationCenter.defaultCenter
   postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];

  // Should invoke networker for locally persisted entry
  OCMVerify(
    ClassMethod(
      [networkerMock sendEntries:[OCMArg checkWithBlock:^BOOL (id obj) {
        XCTAssertEqualObjects(
          obj,
          entries,
          @"Should send the local entries upon foregrounding"
        );
        XCTAssertEqual(
          FBSDKMonitor.entries.count,
          0,
          @"Should clear local entries after sending them"
        );
        return YES;
      }]]
    )
  );
}

- (void)testForegroundingWhenEnabledWithNoLocalEntriesAndPersistedEntries
{
  NSArray<id<FBSDKMonitorEntry>> *entries = @[self.entry];
  [FBSDKMonitor enable];

  // seed store so that there's something to retrieve
  [self.store persist:entries];

  [NSNotificationCenter.defaultCenter
   postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];

  // Should invoke networker if entries are retrieved
  OCMVerify(
    ClassMethod(
      [networkerMock sendEntries:[OCMArg checkWithBlock:^BOOL (id obj) {
        XCTAssertEqualObjects(
          obj,
          entries,
          @"Should send the retrieved entries upon foregrounding"
        );
        XCTAssertEqual(
          FBSDKMonitor.entries.count,
          0,
          @"Should not persist retrieved entries on foregrounding"
        );
        return YES;
      }]]
    )
  );
}

- (void)testForegroundingWhenEnabledWithLocalEntriesAndPersistedEntries
{
  NSArray<id<FBSDKMonitorEntry>> *expectedEntries = @[self.entry, self.entry];
  [FBSDKMonitor enable];
  [FBSDKMonitor record:self.entry];

  // seed store so that there's something to retrieve
  [self.store persist:@[self.entry]];

  [NSNotificationCenter.defaultCenter
   postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];

  // Should invoke networker if entries are retrieved
  OCMVerify(
    ClassMethod(
      [networkerMock sendEntries:[OCMArg checkWithBlock:^BOOL (id obj) {
        XCTAssertEqualObjects(
          obj,
          expectedEntries,
          @"Should send the local and retrieved entries upon foregrounding"
        );
        XCTAssertEqual(
          FBSDKMonitor.entries.count,
          0,
          @"Should not persist retrieved entries on foregrounding"
        );
        return YES;
      }]]
    )
  );
}

- (void)testForegroundingWhenDisabledWithNoEntries
{
  // Should not invoke networker if monitor is disabled
  OCMReject(ClassMethod([networkerMock sendEntries:[OCMArg any]]));

  [NSNotificationCenter.defaultCenter
   postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)testForegroundingWhenDisabledWithEntries
{
  // Should not invoke networker if monitor is disabled
  OCMReject(ClassMethod([networkerMock sendEntries:[OCMArg any]]));

  // seed store so that there's something to fetch
  [self.store persist:@[self.entry]];

  [NSNotificationCenter.defaultCenter
   postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
}

@end
