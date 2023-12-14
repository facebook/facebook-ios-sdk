/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

final class BlocklistEventsManagerTests: XCTestCase {

  static let blocklistedEventName1 = "test_blocklisted_event_name_1"
  static let blocklistedEventName2 = "test_blocklisted_event_name_2"
  static let nonBlocklistedEventName = "test_not_blocklisted_event_name"

  let serverConfigDict = [
    "protectedModeRules": [
      "blocklist_events": [
        BlocklistEventsManagerTests.blocklistedEventName1,
        BlocklistEventsManagerTests.blocklistedEventName2,
      ],
    ],
  ]

  lazy var serverConfiguration = ServerConfigurationFixtures.configuration(withDictionary: serverConfigDict)

  // swiftlint:disable implicitly_unwrapped_optional
  var provider: TestServerConfigurationProvider!
  var blocklistEventsManager: BlocklistEventsManager!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    provider = TestServerConfigurationProvider(configuration: serverConfiguration)
    blocklistEventsManager = BlocklistEventsManager()
    blocklistEventsManager.configuredDependencies = .init(
      serverConfigurationProvider: provider
    )
  }

  override func tearDown() {
    super.tearDown()
    blocklistEventsManager = nil
    provider = nil
  }

  private func getTestEvents() -> NSMutableArray {
    let event1 = [
      AppEvents.ParameterName.eventName: BlocklistEventsManagerTests.blocklistedEventName1,
      AppEvents.ParameterName.currency: "USD",
      AppEvents.ParameterName.description: "This is test event 1 that is blocklisted",
    ]
    let event2 = [
      AppEvents.ParameterName.eventName: BlocklistEventsManagerTests.blocklistedEventName2,
      AppEvents.ParameterName.currency: "EUR",
      AppEvents.ParameterName.description: "This is test event 2 that is blocklisted",
    ]
    let event3 = [
      AppEvents.ParameterName.eventName: BlocklistEventsManagerTests.nonBlocklistedEventName,
      AppEvents.ParameterName.currency: "FEN",
      AppEvents.ParameterName.description: "This is a test event that is not blocklisted",
    ]
    let events = NSMutableArray()
    events.add(["event": event1, "isImplicit": false])
    events.add(["event": event2, "isImplicit": false])
    events.add(["event": event3, "isImplicit": false])
    return events
  }

  func testDefaultDependencies() throws {
    blocklistEventsManager.resetDependencies()
    XCTAssertTrue(
      blocklistEventsManager.serverConfigurationProvider === _ServerConfigurationManager.shared,
      "Should use the shared server configuration manger by default"
    )
  }

  func testConfiguringDependencies() {
    XCTAssertTrue(
      blocklistEventsManager.serverConfigurationProvider === provider,
      "Should be able to create with a server configuration provider"
    )
  }

  func testProcessEventsNotEnabled() {
    let events = getTestEvents()
    blocklistEventsManager.processEvents(events)
    XCTAssertTrue(
      events.count == 3,
      "blocklistEventsManager should not process events when it is not enabled"
    )
    guard let eventDict0 = events[0] as? [String: Any],
          let event0 = eventDict0["event"] as? [AppEvents.ParameterName: String],
          let eventDict1 = events[1] as? [String: Any],
          let event1 = eventDict1["event"] as? [AppEvents.ParameterName: String],
          let eventDict2 = events[2] as? [String: Any],
          let event2 = eventDict2["event"] as? [AppEvents.ParameterName: String] else {
      XCTFail("events has incorrect structure")
      return
    }
    XCTAssertEqual(
      event0[AppEvents.ParameterName.eventName],
      BlocklistEventsManagerTests.blocklistedEventName1,
      "Event at index 0 has an incorrect event name"
    )
    XCTAssertEqual(
      event1[AppEvents.ParameterName.eventName],
      BlocklistEventsManagerTests.blocklistedEventName2,
      "Event at index 1 has an incorrect event name"
    )
    XCTAssertEqual(
      event2[AppEvents.ParameterName.eventName],
      BlocklistEventsManagerTests.nonBlocklistedEventName,
      "Event at index 2 has an incorrect event name"
    )
  }

  func testProcessEventsEnabled() {
    blocklistEventsManager.enable()
    let events = getTestEvents()
    blocklistEventsManager.processEvents(events)
    XCTAssertTrue(
      events.count == 1,
      "blocklistEventsManager should drop blocklisted events when enabled"
    )
    guard let eventDict0 = events[0] as? [String: Any],
          let event0 = eventDict0["event"] as? [AppEvents.ParameterName: String] else {
      XCTFail("events has incorrect structure")
      return
    }
    XCTAssertEqual(
      event0[AppEvents.ParameterName.eventName],
      BlocklistEventsManagerTests.nonBlocklistedEventName,
      "Event at index 0 has an incorrect event name"
    )
  }
}
