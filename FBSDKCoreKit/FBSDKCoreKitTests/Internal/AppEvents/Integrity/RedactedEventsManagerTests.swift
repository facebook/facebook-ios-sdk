/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

final class RedactedEventsManagerTests: XCTestCase {

  let serverConfigDict = [
    "protectedModeRules": [
      "redacted_events": [
        [
          "key": "FilteredEvent",
          "value": ["test_filtered_event_1", "test_filtered_event_2"],
        ],
        [
          "key": "RedactedEvent",
          "value": ["test_redacted_event_1", "test_redacted_event_2"],
        ],
      ],
    ],
  ]

  lazy var serverConfiguration = ServerConfigurationFixtures.configuration(withDictionary: serverConfigDict)

  // swiftlint:disable implicitly_unwrapped_optional
  var provider: TestServerConfigurationProvider!
  var redactedEventsManager: RedactedEventsManager!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    provider = TestServerConfigurationProvider(configuration: serverConfiguration)
    redactedEventsManager = RedactedEventsManager()
    redactedEventsManager.configuredDependencies = .init(
      serverConfigurationProvider: provider
    )
  }

  override func tearDown() {
    super.tearDown()
    redactedEventsManager = nil
    provider = nil
  }

  private func getTestEvents() -> NSMutableArray {
    let event1 = [
      AppEvents.ParameterName.eventName: "test_filtered_event_1",
      AppEvents.ParameterName.currency: "USD",
      AppEvents.ParameterName.description: "This is a filtered event",
    ]
    let event2 = [
      AppEvents.ParameterName.eventName: "test_filtered_event_2",
      AppEvents.ParameterName.currency: "EUR",
      AppEvents.ParameterName.description: "This is a filtered event",
    ]
    let event3 = [
      AppEvents.ParameterName.eventName: "test_redacted_event_1",
      AppEvents.ParameterName.currency: "FEN",
      AppEvents.ParameterName.description: "This is a redacted event",
    ]
    let event4 = [
      AppEvents.ParameterName.eventName: "test_redacted_event_2",
      AppEvents.ParameterName.currency: "GBP",
      AppEvents.ParameterName.description: "This is a redacted event",
    ]
    let event5 = [
      AppEvents.ParameterName.eventName: "test_non_sensitive_event",
      AppEvents.ParameterName.currency: "CAD",
      AppEvents.ParameterName.description: "This is a non-sensitive event",
    ]
    let events = NSMutableArray()
    events.add(["event": event1, "isImplicit": false])
    events.add(["event": event2, "isImplicit": false])
    events.add(["event": event3, "isImplicit": false])
    events.add(["event": event4, "isImplicit": false])
    events.add(["event": event5, "isImplicit": false])
    return events
  }

  func testDefaultDependencies() throws {
    redactedEventsManager.resetDependencies()
    XCTAssertTrue(
      redactedEventsManager.serverConfigurationProvider === _ServerConfigurationManager.shared,
      "Should use the shared server configuration manger by default"
    )
  }

  func testConfiguringDependencies() {
    XCTAssertTrue(
      redactedEventsManager.serverConfigurationProvider === provider,
      "Should be able to create with a server configuration provider"
    )
  }

  func testProcessEventsNotEnabled() {
    let events = getTestEvents()
    redactedEventsManager.processEvents(events)
    XCTAssertTrue(
      events.count == 5,
      "redactedEventsManager should not drop any events"
    )
    guard let eventDict0 = events[0] as? [String: Any],
          let event0 = eventDict0["event"] as? [AppEvents.ParameterName: String],
          let eventDict1 = events[1] as? [String: Any],
          let event1 = eventDict1["event"] as? [AppEvents.ParameterName: String],
          let eventDict2 = events[2] as? [String: Any],
          let event2 = eventDict2["event"] as? [AppEvents.ParameterName: String],
          let eventDict3 = events[3] as? [String: Any],
          let event3 = eventDict3["event"] as? [AppEvents.ParameterName: String],
          let eventDict4 = events[4] as? [String: Any],
          let event4 = eventDict4["event"] as? [AppEvents.ParameterName: String] else {
      XCTFail("events has incorrect structure")
      return
    }
    XCTAssertEqual(
      event0[AppEvents.ParameterName.eventName],
      "test_filtered_event_1",
      "Event at index 0 has an incorrect event name"
    )
    XCTAssertEqual(
      event1[AppEvents.ParameterName.eventName],
      "test_filtered_event_2",
      "Event at index 1 has an incorrect event name"
    )
    XCTAssertEqual(
      event2[AppEvents.ParameterName.eventName],
      "test_redacted_event_1",
      "Event at index 2 has an incorrect event name"
    )
    XCTAssertEqual(
      event3[AppEvents.ParameterName.eventName],
      "test_redacted_event_2",
      "Event at index 3 has an incorrect event name"
    )
    XCTAssertEqual(
      event4[AppEvents.ParameterName.eventName],
      "test_non_sensitive_event",
      "Event at index 4 has an incorrect event name"
    )
  }

  func testProcessEventsEnabled() {
    redactedEventsManager.enable()
    let events = getTestEvents()
    redactedEventsManager.processEvents(events)
    XCTAssertTrue(
      events.count == 5,
      "redactedEventsManager should not drop any events"
    )
    guard let eventDict0 = events[0] as? [String: Any],
          let event0 = eventDict0["event"] as? [AppEvents.ParameterName: String],
          let eventDict1 = events[1] as? [String: Any],
          let event1 = eventDict1["event"] as? [AppEvents.ParameterName: String],
          let eventDict2 = events[2] as? [String: Any],
          let event2 = eventDict2["event"] as? [AppEvents.ParameterName: String],
          let eventDict3 = events[3] as? [String: Any],
          let event3 = eventDict3["event"] as? [AppEvents.ParameterName: String],
          let eventDict4 = events[4] as? [String: Any],
          let event4 = eventDict4["event"] as? [AppEvents.ParameterName: String] else {
      XCTFail("events has incorrect structure")
      return
    }
    XCTAssertEqual(
      event0[AppEvents.ParameterName.eventName],
      "FilteredEvent",
      "Event at index 0 has an incorrect event name"
    )
    XCTAssertEqual(
      event1[AppEvents.ParameterName.eventName],
      "FilteredEvent",
      "Event at index 1 has an incorrect event name"
    )
    XCTAssertEqual(
      event2[AppEvents.ParameterName.eventName],
      "RedactedEvent",
      "Event at index 2 has an incorrect event name"
    )
    XCTAssertEqual(
      event3[AppEvents.ParameterName.eventName],
      "RedactedEvent",
      "Event at index 3 has an incorrect event name"
    )
    XCTAssertEqual(
      event4[AppEvents.ParameterName.eventName],
      "test_non_sensitive_event",
      "Event at index 4 has an incorrect event name"
    )
  }
}
