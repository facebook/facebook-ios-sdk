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
  let testEvent1 = "test_event_name_1"
  let testEvent2 = "test_event_name_2"
  lazy var events = [testEvent1, testEvent2]

  func testGeneralServerResponse() {
    let serverResponse = [
      testEvent1: [
        "restrictive_param": restrictiveParam1,
        "deprecated_param": deprecatedParam1,
        "is_deprecated_event": true
      ],
      testEvent2: [
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
    XCTAssertEqual("test_event_name_1", eventData1.eventName)
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
    XCTAssertEqual("test_event_name_2", eventData2.eventName)
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
      testEvent1: [
        "restrictive_param": restrictiveParam1,
        "deprecated_param": deprecatedParam1,
        "new_filed": "new_filed_string_1",
        "is_deprecated_event": true,
      ],
      testEvent2: [
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
    XCTAssertEqual("test_event_name_1", eventData1.eventName)
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
    XCTAssertEqual("test_event_name_2", eventData2.eventName)
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
      testEvent1: [
        "deprecated_param": deprecatedParam1,
        "is_deprecated_event": true,
      ],
      testEvent2: [
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
      "test_event_name_1",
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
    XCTAssertEqual("test_event_name_2", eventData2.eventName)
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
      testEvent1: [
        "restrictive_param": restrictiveParam1,
        "is_deprecated_event": true,
      ],
      testEvent2: [
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
    XCTAssertEqual("test_event_name_1", eventData1.eventName)
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
    XCTAssertEqual("test_event_name_2", eventData2.eventName)
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
      testEvent1: [
        "restrictive_param": restrictiveParam1,
        "deprecated_param": deprecatedParam1,
      ],
      testEvent2: [
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
    XCTAssertEqual("test_event_name_1", eventData1.eventName)
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
    XCTAssertEqual("test_event_name_2", eventData2.eventName)
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
      testEvent1: [
        "restrictive_param": [:],
        "deprecated_param": deprecatedParam1,
        "is_deprecated_event": true,
      ],
      testEvent2: [
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
    XCTAssertEqual("test_event_name_1", eventData1.eventName)
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
    XCTAssertEqual("test_event_name_2", eventData2.eventName)
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
      testEvent1: [
        "restrictive_param": restrictiveParam1,
        "deprecated_param": [],
        "is_deprecated_event": true,
      ],
      testEvent2: [
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
    XCTAssertEqual("test_event_name_1", eventData1.eventName)
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
    XCTAssertEqual("test_event_name_2", eventData2.eventName)
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
    events: [String],
    response: [String: Any]
  ) -> [RestrictiveData] {
    events.map {
      RestrictiveData(
        eventName: $0,
        params: response[$0] as Any
      )
    }
  }
}  // swiftlint:disable:this file_length
