/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

class RestrictiveDataTests: XCTestCase {

  let restrictiveParam1 = [
    "restrictive_key_1": "restrictive_value_1",
    "restrictive_key_2": "restrictive_value_2"
  ]
  let restrictiveParam2 = [
    "restrictive_key_1": "restrictive_value_3",
    "restrictive_key_2": "restrictive_value_4"
  ]
  let deprecatedParam1 = ["deprecated_value_1", "deprecated_value_2"]
  let deprecatedParam2 = ["deprecated_value_3", "deprecated_value_4"]
  let testEvent1 = AppEvents.Name("test_event_name_1")
  let testEvent2 = AppEvents.Name("test_event_name_2")
  lazy var events = [testEvent1, testEvent2]

  func testGeneralServerResponse() {
    let serverResponse = [
      testEvent1.rawValue: [
        "restrictive_param": restrictiveParam1,
        "deprecated_param": deprecatedParam1,
        "is_deprecated_event": true
      ],
      testEvent2.rawValue: [
        "restrictive_param": restrictiveParam2,
        "deprecated_param": deprecatedParam2,
        "is_deprecated_event": false
      ]
    ]

    let restrictiveData = createRestrictiveData(
      events: events,
      response: serverResponse
    )
    XCTAssertEqual(2, restrictiveData.count, "Unexpected count")

    let eventData1 = restrictiveData[0]
    XCTAssertEqual(AppEvents.Name("test_event_name_1"), eventData1.eventName)
    XCTAssertEqual(
      restrictiveParam1,
      eventData1.restrictiveParams,
      "The FBSDKRestrictiveData's eventName property should be equal to the actual event name."
    )
    XCTAssertEqual(
      deprecatedParam1,
      eventData1.deprecatedParams,
      "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field."
    )
    XCTAssertTrue(
      eventData1.deprecatedEvent,
      "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field."
    )
    let eventData2 = restrictiveData[1]
    XCTAssertEqual(AppEvents.Name("test_event_name_2"), eventData2.eventName)
    XCTAssertEqual(
      restrictiveParam2,
      eventData2.restrictiveParams,
      "The FBSDKRestrictiveData's eventName property should be equal to the actual event name."
    )
    XCTAssertEqual(
      deprecatedParam2,
      eventData2.deprecatedParams,
      "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field."
    )
    XCTAssertFalse(
      eventData2.deprecatedEvent,
      "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field."
    )
  }

  func testServerResponseWithExtraFields() { // swiftlint:disable:this function_body_length
    let serverResponse = [
      testEvent1.rawValue: [
        "restrictive_param": restrictiveParam1,
        "deprecated_param": deprecatedParam1,
        "new_filed": "new_filed_string_1",
        "is_deprecated_event": true,
      ],
      testEvent2.rawValue: [
        "restrictive_param": restrictiveParam2,
        "deprecated_param": deprecatedParam2,
        "new_filed": "new_filed_string_2",
        "is_deprecated_event": false,
      ]
    ]
    let restrictiveData = createRestrictiveData(
      events: events,
      response: serverResponse
    )
    XCTAssertEqual(2, restrictiveData.count, "Unexpected count")

    let eventData1 = restrictiveData[0]
    XCTAssertEqual(AppEvents.Name("test_event_name_1"), eventData1.eventName)
    XCTAssertEqual(
      restrictiveParam1,
      eventData1.restrictiveParams,
      "The FBSDKRestrictiveData's eventName property should be equal to the actual event name."
    )
    XCTAssertEqual(
      deprecatedParam1,
      eventData1.deprecatedParams,
      "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field."
    )
    XCTAssertTrue(
      eventData1.deprecatedEvent,
      "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field."
    )
    let eventData2 = restrictiveData[1]
    XCTAssertEqual(AppEvents.Name("test_event_name_2"), eventData2.eventName)
    XCTAssertEqual(
      restrictiveParam2,
      eventData2.restrictiveParams,
      "The FBSDKRestrictiveData's eventName property should be equal to the actual event name."
    )
    XCTAssertEqual(
      deprecatedParam2,
      eventData2.deprecatedParams,
      "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field."
    )
    XCTAssertFalse(
      eventData2.deprecatedEvent,
      "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field."
    )
  }

  func testServerResponseWithMissingRestrictiveParam() {
    let serverResponse = [
      testEvent1.rawValue: [
        "deprecated_param": deprecatedParam1,
        "is_deprecated_event": true,
      ],
      testEvent2.rawValue: [
        "deprecated_param": deprecatedParam2,
        "is_deprecated_event": false,
      ]
    ]
    let restrictiveData = createRestrictiveData(
      events: events,
      response: serverResponse
    )
    XCTAssertEqual(2, restrictiveData.count, "Unexpected count")

    let eventData1 = restrictiveData[0]
    XCTAssertEqual(
      AppEvents.Name("test_event_name_1"),
      eventData1.eventName
    )
    XCTAssertNil(
      eventData1.restrictiveParams,
      "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field."
    )
    XCTAssertEqual(
      deprecatedParam1,
      eventData1.deprecatedParams,
      "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field."
    )
    XCTAssertTrue(
      eventData1.deprecatedEvent,
      "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field."
    )
    let eventData2 = restrictiveData[1]
    XCTAssertEqual(AppEvents.Name("test_event_name_2"), eventData2.eventName)
    XCTAssertNil(
      eventData2.restrictiveParams,
      "The FBSDKRestrictiveData's eventName property should be equal to the actual event name."
    )
    XCTAssertEqual(
      deprecatedParam2,
      eventData2.deprecatedParams,
      "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field."
    )
    XCTAssertFalse(
      eventData2.deprecatedEvent,
      "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field."
    )
  }

  func testServerResponseWithMissingDeprecatedParam() {
    let serverResponse = [
      testEvent1.rawValue: [
        "restrictive_param": restrictiveParam1,
        "is_deprecated_event": true,
      ],
      testEvent2.rawValue: [
        "restrictive_param": restrictiveParam2,
        "is_deprecated_event": false,
      ]
    ]
    let restrictiveData = createRestrictiveData(
      events: events,
      response: serverResponse
    )
    XCTAssertEqual(2, restrictiveData.count, "Unexpected count")

    let eventData1 = restrictiveData[0]
    XCTAssertEqual(AppEvents.Name("test_event_name_1"), eventData1.eventName)
    XCTAssertEqual(
      restrictiveParam1,
      eventData1.restrictiveParams,
      "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field."
    )
    XCTAssertNil(
      eventData1.deprecatedParams,
      "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field."
    )
    XCTAssertTrue(
      eventData1.deprecatedEvent,
      "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field."
    )
    let eventData2 = restrictiveData[1]
    XCTAssertEqual(AppEvents.Name("test_event_name_2"), eventData2.eventName)
    XCTAssertEqual(
      restrictiveParam2,
      eventData2.restrictiveParams,
      "The FBSDKRestrictiveData's eventName property should be equal to the actual event name."
    )
    XCTAssertNil(
      eventData2.deprecatedParams,
      "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field."
    )
    XCTAssertFalse(
      eventData2.deprecatedEvent,
      "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field."
    )
  }

  func testServerResponseWithMissingIsDeprecatedEvent() {
    let serverResponse = [
      testEvent1.rawValue: [
        "restrictive_param": restrictiveParam1,
        "deprecated_param": deprecatedParam1,
      ],
      testEvent2.rawValue: [
        "restrictive_param": restrictiveParam2,
        "deprecated_param": deprecatedParam2
      ]
    ]
    let restrictiveData = createRestrictiveData(
      events: events,
      response: serverResponse
    )
    XCTAssertEqual(2, restrictiveData.count, "Unexpected count")

    let eventData1 = restrictiveData[0]
    XCTAssertEqual(AppEvents.Name("test_event_name_1"), eventData1.eventName)
    XCTAssertEqual(
      restrictiveParam1,
      eventData1.restrictiveParams,
      "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field."
    )
    XCTAssertEqual(
      deprecatedParam1,
      eventData1.deprecatedParams,
      "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field."
    )
    XCTAssertFalse(
      eventData1.deprecatedEvent,
      "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field."
    )
    let eventData2 = restrictiveData[1]
    XCTAssertEqual(AppEvents.Name("test_event_name_2"), eventData2.eventName)
    XCTAssertEqual(
      restrictiveParam2,
      eventData2.restrictiveParams,
      "The FBSDKRestrictiveData's eventName property should be equal to the actual event name."
    )
    XCTAssertEqual(
      deprecatedParam2,
      eventData2.deprecatedParams,
      "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field."
    )
    XCTAssertFalse(
      eventData2.deprecatedEvent,
      "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field."
    )
  }

  func testServerResponseWithEmptyRestrictiveParam() {
    let serverResponse = [
      testEvent1.rawValue: [
        "restrictive_param": [:],
        "deprecated_param": deprecatedParam1,
        "is_deprecated_event": true,
      ],
      testEvent2.rawValue: [
        "restrictive_param": [:],
        "deprecated_param": deprecatedParam2,
        "is_deprecated_event": false
      ]
    ]
    let restrictiveData = createRestrictiveData(
      events: events,
      response: serverResponse
    )
    XCTAssertEqual(2, restrictiveData.count, "Unexpected count")

    let eventData1 = restrictiveData[0]
    XCTAssertEqual(AppEvents.Name("test_event_name_1"), eventData1.eventName)
    XCTAssertEqual(
      [:],
      eventData1.restrictiveParams,
      "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field."
    )
    XCTAssertEqual(
      deprecatedParam1,
      eventData1.deprecatedParams,
      "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field."
    )
    XCTAssertTrue(
      eventData1.deprecatedEvent,
      "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field."
    )
    let eventData2 = restrictiveData[1]
    XCTAssertEqual(AppEvents.Name("test_event_name_2"), eventData2.eventName)
    XCTAssertEqual(
      [:],
      eventData2.restrictiveParams,
      "The FBSDKRestrictiveData's eventName property should be equal to the actual event name."
    )

    XCTAssertEqual(
      deprecatedParam2,
      eventData2.deprecatedParams,
      "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field."
    )
    XCTAssertFalse(
      eventData2.deprecatedEvent,
      "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field."
    )
  }

  func testServerResponseWithEmptyDeprecatedParam() {
    let serverResponse = [
      testEvent1.rawValue: [
        "restrictive_param": restrictiveParam1,
        "deprecated_param": [],
        "is_deprecated_event": true,
      ],
      testEvent2.rawValue: [
        "restrictive_param": restrictiveParam2,
        "deprecated_param": [],
        "is_deprecated_event": false
      ]
    ]
    let restrictiveData = createRestrictiveData(
      events: events,
      response: serverResponse
    )
    XCTAssertEqual(2, restrictiveData.count, "Unexpected count")

    let eventData1 = restrictiveData[0]
    XCTAssertEqual(AppEvents.Name("test_event_name_1"), eventData1.eventName)
    XCTAssertEqual(
      restrictiveParam1,
      eventData1.restrictiveParams,
      "The FBSDKRestrictiveData's restrictiveParams property should be equal to the actual restrictive_param field."
    )
    XCTAssertEqual(
      [],
      eventData1.deprecatedParams,
      "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field."
    )
    XCTAssertTrue(
      eventData1.deprecatedEvent,
      "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field."
    )
    let eventData2 = restrictiveData[1]
    XCTAssertEqual(AppEvents.Name("test_event_name_2"), eventData2.eventName)
    XCTAssertEqual(
      restrictiveParam2,
      eventData2.restrictiveParams,
      "The FBSDKRestrictiveData's eventName property should be equal to the actual event name."
    )
    XCTAssertEqual(
      [],
      eventData2.deprecatedParams,
      "The FBSDKRestrictiveData's deprecatedParams property should be equal to the actual deprecated_param field."
    )
    XCTAssertFalse(
      eventData2.deprecatedEvent,
      "The FBSDKRestrictiveData's deprecatedEvent property should be equal to the actual is_deprecated_event field."
    )
  }

  func createRestrictiveData(
    events: [AppEvents.Name],
    response: [String: Any]
  ) -> [RestrictiveData] {
    events.map {
      RestrictiveData(
        eventName: $0,
        params: response[$0.rawValue] as Any
      )
    }
  }
}  // swiftlint:disable:this file_length
