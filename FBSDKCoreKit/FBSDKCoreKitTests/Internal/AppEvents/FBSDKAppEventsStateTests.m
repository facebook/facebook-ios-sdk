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

#import "FBSDKAppEventsState.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKTestCase.h"
#import "SampleAppEvents.h"

#define FBSDK_APPEVENTSSTATE_MAX_EVENTS 1000

@interface FBSDKAppEventsStateTests : FBSDKTestCase
@end

@implementation FBSDKAppEventsStateTests
{
  FBSDKAppEventsState *_state;
  FBSDKAppEventsState *_partiallyFullState;
  FBSDKAppEventsState *_fullState;
}

- (void)setUp
{
  [super setUp];

  [self.appEventStatesMock stopMocking];
  [self setUpFixtures];
}

- (void)setUpFixtures
{
  _state = [[FBSDKAppEventsState alloc] initWithToken:self.name appID:self.appID];
  XCTAssertEqual(0, _state.events.count, "sanity check");

  _partiallyFullState = [[FBSDKAppEventsState alloc] initWithToken:self.name appID:self.appID];
  [_partiallyFullState addEvent:SampleAppEvents.validEvent isImplicit:NO];
  XCTAssertEqual(1, _partiallyFullState.events.count, "sanity check");

  _fullState = [[FBSDKAppEventsState alloc] initWithToken:self.name appID:self.appID];
  for (size_t i = 0; i < FBSDK_APPEVENTSSTATE_MAX_EVENTS; ++i) {
    [_fullState addEvent:SampleAppEvents.validEvent isImplicit:NO];
  }
  XCTAssertEqual(FBSDK_APPEVENTSSTATE_MAX_EVENTS, _fullState.events.count, "sanity check");
}

- (void)testDefaults
{
  XCTAssertEqual(0, _state.events.count, "Should have no events by default");
  XCTAssertEqual(0, _state.numSkipped, "Should have no skipped events by default");
  XCTAssertTrue(
    [_state areAllEventsImplicit],
    "Should consider all events to be implicit when there are no events"
  );
}

- (void)testCreatingWithNilTokenNilAppID
{
  XCTAssertNotNil(
    [[FBSDKAppEventsState alloc] initWithToken:nil appID:nil],
    "Should not create app events state with missing token and app id but you can"
  );
}

- (void)testCreatingWithNilTokenInvalidAppID
{
  XCTAssertNotNil(
    [[FBSDKAppEventsState alloc] initWithToken:nil appID:@""],
    "Should not create app events state with missing token and empty app id but you can"
  );
  XCTAssertNotNil(
    [[FBSDKAppEventsState alloc] initWithToken:nil appID:@"   "],
    "Should not create app events state with missing token and whitespace only app id but you can"
  );
}

- (void)testCreatingWithNilTokenValidAppID
{
  XCTAssertNotNil(
    [[FBSDKAppEventsState alloc] initWithToken:nil appID:self.appID],
    "Should not create app events state with missing token and valid app id but you can"
  );
}

- (void)testCreatingWithInvalidTokenNilAppID
{
  XCTAssertNotNil(
    [[FBSDKAppEventsState alloc] initWithToken:@"" appID:nil],
    "Should not create app events state with empty token and missing app id but you can"
  );
  XCTAssertNotNil(
    [[FBSDKAppEventsState alloc] initWithToken:@"    " appID:nil],
    "Should not create app events state with whitespace only token and missing app id but you can"
  );
}

- (void)testCreatingWithInvalidTokenInvalidAppID
{
  XCTAssertNotNil(
    [[FBSDKAppEventsState alloc] initWithToken:@"" appID:@""],
    "Should not create app events state with invalid token and invalid app id but you can"
  );
}

- (void)testCreatingWithInvalidTokenValidAppID
{
  XCTAssertNotNil(
    [[FBSDKAppEventsState alloc] initWithToken:@"" appID:self.appID],
    "Should not create app events state with empty token and valid app id but you can"
  );
  XCTAssertNotNil(
    [[FBSDKAppEventsState alloc] initWithToken:@"    " appID:nil],
    "Should not create app events state with whitespace only token and valid app id but you can"
  );
}

- (void)testCreatingWithValidTokenNilAppID
{
  XCTAssertNotNil(
    [[FBSDKAppEventsState alloc] initWithToken:self.name appID:nil],
    "Should not create app events state with valid token and missing app id but you can"
  );
}

- (void)testCreatingWithValidTokenInvalidAppID
{
  XCTAssertNotNil(
    [[FBSDKAppEventsState alloc] initWithToken:self.name appID:@""],
    "Should not create app events state with valid token and empty app id but you can"
  );
  XCTAssertNotNil(
    [[FBSDKAppEventsState alloc] initWithToken:self.name appID:@"   "],
    "Should not create app events state with valid token and whitespace only app id but you can"
  );
}

- (void)testCreatingWithValidTokenValidAppID
{
  XCTAssertNotNil(
    [[FBSDKAppEventsState alloc] initWithToken:self.name appID:self.appID],
    "Should be able to create app events state with valid token and app id"
  );
}

// MARK: - Adding Events

- (void)testAddingDuplicateEvents
{
  [_state addEvent:SampleAppEvents.validEvent isImplicit:YES];
  [_state addEvent:SampleAppEvents.validEvent isImplicit:YES];

  XCTAssertEqual(2, _state.events.count, "Should be able to add duplicate events");
  XCTAssertEqual(0, _state.numSkipped, "Should not skip valid events");
}

- (void)testAddingSingleImplicitEvent
{
  [_state addEvent:SampleAppEvents.validEvent isImplicit:YES];

  XCTAssertEqual(1, _state.events.count, "Should be able to add a valid event");
  XCTAssertEqual(0, _state.numSkipped, "Should not skip valid events");
  XCTAssertTrue(
    [_state areAllEventsImplicit],
    "Should consider all events to be implicit when all events were added as implicit"
  );
}

- (void)testAddingMultipleImplicitEvents
{
  [_state addEvent:SampleAppEvents.validEvent isImplicit:YES];
  [_state addEvent:[SampleAppEvents validEventWithName:@"event2"] isImplicit:YES];

  XCTAssertEqual(2, _state.events.count, "Should be able to add multiple valid events");
  XCTAssertEqual(0, _state.numSkipped, "Should not skip valid events");
  XCTAssertTrue(
    [_state areAllEventsImplicit],
    "Should consider all events to be implicit when all events were added as implicit"
  );
}

- (void)testAddingSingleNonImplicitEvents
{
  [_state addEvent:SampleAppEvents.validEvent isImplicit:NO];

  XCTAssertEqual(1, _state.events.count, "Should be able to add a valid event");
  XCTAssertEqual(0, _state.numSkipped, "Should not skip valid events");
  XCTAssertFalse(
    [_state areAllEventsImplicit],
    "Should not consider all events to be implicit when no events were added as implicit"
  );
}

- (void)testAddingMultipleNonImplicitEvents
{
  [_state addEvent:SampleAppEvents.validEvent isImplicit:NO];
  [_state addEvent:[SampleAppEvents validEventWithName:@"event2"] isImplicit:NO];

  XCTAssertEqual(2, _state.events.count, "Should be able to add multiple valid events");
  XCTAssertEqual(0, _state.numSkipped, "Should not skip valid events");
  XCTAssertFalse(
    [_state areAllEventsImplicit],
    "Should not consider all events to be implicit when no events were added as implicit"
  );
}

- (void)testAddingMixtureOfImplicitNonImplicitEvents
{
  [_state addEvent:SampleAppEvents.validEvent isImplicit:YES];
  [_state addEvent:[SampleAppEvents validEventWithName:@"event2"] isImplicit:NO];

  XCTAssertEqual(2, _state.events.count, "Should be able to mix implicit and explicit events");
  XCTAssertEqual(0, _state.numSkipped, "Should not skip valid events");
  XCTAssertFalse(
    [_state areAllEventsImplicit],
    "Should not consider all events to be implicit when at least one event is non-implicit"
  );
}

- (void)testAddingEventAtMaxCapacity
{
  [_fullState addEvent:SampleAppEvents.validEvent isImplicit:NO];
  [_fullState addEvent:SampleAppEvents.validEvent isImplicit:NO];

  XCTAssertEqual(2, _fullState.numSkipped, "Should skip any events added after the max size is reached");
}

// MARK: - Events from AppEventState

- (void)testAddingEventsToDuplicateEvents
{
  [_partiallyFullState addEventsFromAppEventState:_partiallyFullState];

  XCTAssertEqual(2, _partiallyFullState.events.count, "Duplicate event states should not be addable but they are");
  XCTAssertEqual(0, _partiallyFullState.numSkipped, "Duplicate event states should not be addable but they are");
}

- (void)testAddingEventsFromEmptyStateToEmptyState
{
  FBSDKAppEventsState *state2 = [[FBSDKAppEventsState alloc] initWithToken:self.name appID:self.appID];

  [_state addEventsFromAppEventState:state2];

  XCTAssertEqual(0, _state.events.count, "Adding an empty state to an empty state should have no effect");
  XCTAssertEqual(0, _state.numSkipped, "Adding an empty state to an empty state should have no effect");
}

- (void)testAddEventsFromFullStateToEmptyState
{
  [_state addEventsFromAppEventState:_fullState];

  XCTAssertEqual(
    FBSDK_APPEVENTSSTATE_MAX_EVENTS,
    _state.events.count,
    "Should add all the events from the other state"
  );
  XCTAssertEqual(
    0,
    _state.numSkipped,
    "Should not skip events when there is room in the state to hold them"
  );
}

- (void)testAddEventsFromEmptyStateToPartiallyFilledState
{
  FBSDKAppEventsState *emptyState = [[FBSDKAppEventsState alloc] initWithToken:self.name appID:self.appID];
  [_state addEvent:SampleAppEvents.validEvent isImplicit:YES];

  [_state addEventsFromAppEventState:emptyState];

  XCTAssertEqual(1, _state.events.count, "Adding an empty state to a partially filled state should have no effect");
  XCTAssertEqual(0, _state.numSkipped, "Adding an empty state to a partially filled state should have no effect");
}

- (void)testAddEventsFromPartiallyFilledStateToEmptyState
{
  [_state addEventsFromAppEventState:_partiallyFullState];

  XCTAssertEqual(1, _state.events.count, "Should add all the events in the partially filled state to the empty state");
  XCTAssertEqual(0, _state.numSkipped, "Adding a partially filled state to an empty state should have no effect");
}

- (void)testAddEventsFromPartiallyFilledStateToFullState
{
  [_fullState addEventsFromAppEventState:_partiallyFullState];

  XCTAssertEqual(FBSDK_APPEVENTSSTATE_MAX_EVENTS, _fullState.events.count, "Adding to a full state should have no effect on the event count");
  XCTAssertEqual(1, _fullState.numSkipped, "Should skip events in excess of a state's capacity");
}

- (void)testAddEventsFromFullStateToPartiallyFilledState
{
  [_partiallyFullState addEventsFromAppEventState:_fullState];

  XCTAssertEqual(
    FBSDK_APPEVENTSSTATE_MAX_EVENTS,
    _partiallyFullState.events.count,
    "Adding a full state to a partially filled state should add as many events as possible"
  );
  XCTAssertEqual(1, _partiallyFullState.numSkipped, "Should skip events in excess of a state's capacity");
}

- (void)testAddEventsFromFullStateToFullState
{
  FBSDKAppEventsState *otherFullState = [[FBSDKAppEventsState alloc] initWithToken:self.name appID:self.appID];

  for (size_t i = 0; i < FBSDK_APPEVENTSSTATE_MAX_EVENTS * 2; ++i) {
    [otherFullState addEvent:SampleAppEvents.validEvent isImplicit:NO];
  }

  [_fullState addEventsFromAppEventState:otherFullState];

  XCTAssertEqual(
    FBSDK_APPEVENTSSTATE_MAX_EVENTS,
    _fullState.events.count,
    "Should not add additional events to a full state"
  );
  XCTAssertEqual(FBSDK_APPEVENTSSTATE_MAX_EVENTS, _fullState.events.count, "Adding to a full state should have no effect on the event count");
}

- (void)testAddEventsToPreviouslyOverflownState
{
  // Fills
  [_state addEventsFromAppEventState:_fullState];
  // Overflows
  [_state addEventsFromAppEventState:_fullState];
  // Double overflows
  [_state addEventsFromAppEventState:_fullState];

  XCTAssertEqual(
    FBSDK_APPEVENTSSTATE_MAX_EVENTS * 2,
    _state.numSkipped,
    "Should keep a running count of skipped states"
  );
  XCTAssertEqual(
    FBSDK_APPEVENTSSTATE_MAX_EVENTS,
    _state.events.count,
    "Should not add additional events to a full state"
  );
}

// MARK: - Compatibility

- (void)testCompatibilityWithMatchingTokenMatchingAppID
{
  FBSDKAppEventsState *state2 = [[FBSDKAppEventsState alloc] initWithToken:self.name appID:self.appID];
  XCTAssertTrue(
    [_state isCompatibleWithAppEventsState:state2],
    "States with matching tokens and matching app ids should be compatible"
  );
}

- (void)testMatchingTokenNonMatchingAppID
{
  FBSDKAppEventsState *state2 = [[FBSDKAppEventsState alloc] initWithToken:self.name appID:self.name];
  XCTAssertFalse(
    [_state isCompatibleWithAppEventsState:state2],
    "States with matching tokens and non-matching app ids should not be compatible"
  );
}

- (void)testNonMatchingTokenMatchingAppID
{
  FBSDKAppEventsState *state2 = [[FBSDKAppEventsState alloc] initWithToken:self.appID appID:self.appID];
  XCTAssertFalse(
    [_state isCompatibleWithAppEventsState:state2],
    "States with matching non-matching tokens and matching app ids should not be compatible"
  );
}

- (void)testNonMatchingTokenNonMatchingAppID
{
  FBSDKAppEventsState *state2 = [[FBSDKAppEventsState alloc] initWithToken:self.appID appID:self.name];
  XCTAssertFalse(
    [_state isCompatibleWithAppEventsState:state2],
    "States with matching non-matching tokens and non matching app ids should not be compatible"
  );
}

- (void)testNilTokensMatchingAppID
{
  FBSDKAppEventsState *state1 = [[FBSDKAppEventsState alloc] initWithToken:nil appID:self.appID];
  FBSDKAppEventsState *state2 = [[FBSDKAppEventsState alloc] initWithToken:nil appID:self.appID];

  XCTAssertTrue(
    [state1 isCompatibleWithAppEventsState:state2],
    "States with nil tokens and matching app ids should be compatible"
  );
}

- (void)testNilTokensNonMatchingAppID
{
  FBSDKAppEventsState *state1 = [[FBSDKAppEventsState alloc] initWithToken:nil appID:self.appID];
  FBSDKAppEventsState *state2 = [[FBSDKAppEventsState alloc] initWithToken:nil appID:self.name];

  XCTAssertFalse(
    [state1 isCompatibleWithAppEventsState:state2],
    "States with nil tokens and non-matching app ids should not be compatible"
  );
}

// MARK: - Extract Receipt Data

- (void)testExtractReceiptData
{
  [_state addEvent:@{@"receipt_data" : @"some_data"} isImplicit:NO];
  NSString *extracted = [_state extractReceiptData];

  XCTAssertTrue([extracted isEqualToString:@"receipt_1::some_data;;;"]);
}

// MARK: - JSONString For Events

- (void)testJSONStringForEventsWithNoEvents
{
  NSString *json = [_state JSONStringForEvents:YES];
  NSString *expected = [FBSDKBasicUtility JSONStringForObject:@[] error:nil invalidObjectHandler:nil];

  XCTAssertEqualObjects(json, expected, "Should represent events as empty json array when there are no events");
}

- (void)testJSONStringForEventsIncludingImplicitEvents
{
  [_state addEvent:SampleAppEvents.validEvent isImplicit:YES];
  [_state addEvent:SampleAppEvents.validEvent isImplicit:YES];

  NSString *json = [_state JSONStringForEvents:YES];
  NSString *expected = [FBSDKBasicUtility JSONStringForObject:@[SampleAppEvents.validEvent, SampleAppEvents.validEvent] error:nil invalidObjectHandler:nil];

  XCTAssertEqualObjects(json, expected, "Should represent events as empty json array when there are no events");
}

- (void)testJSONStringForEventsExcludingImplicitEvents
{
  [_state addEvent:SampleAppEvents.validEvent isImplicit:YES];
  [_state addEvent:SampleAppEvents.validEvent isImplicit:NO];

  NSString *json = [_state JSONStringForEvents:NO];

  NSString *expected = [FBSDKBasicUtility JSONStringForObject:@[SampleAppEvents.validEvent] error:nil invalidObjectHandler:nil];

  XCTAssertEqualObjects(json, expected, "Should represent events as empty json array when there are no events");
}

@end
