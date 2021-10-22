/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class FBSDKRestrictiveDataFilterTests: XCTestCase {
  var restrictiveDataFilterManager: RestrictiveDataFilterManager = createTestRestrictiveDataFilterManager()

  private static func createTestRestrictiveDataFilterManager() -> RestrictiveDataFilterManager {
    let params = [
      "test_event_name": [
        "restrictive_param": [
          "first name": "6",
          "last name": "7"
        ]
      ],
      "restrictive_event_name": [
        "restrictive_param": [
          "dob": 4
        ]
      ]
    ]
    let config = ServerConfigurationFixtures.config(withDictionary: [
      "restrictiveParams": params
    ])
    let serverConfigProider = TestServerConfigurationProvider(configuration: config)
    let restrictiveDataFilterManager = RestrictiveDataFilterManager(serverConfigurationProvider: serverConfigProider)
    restrictiveDataFilterManager.enable()
    return restrictiveDataFilterManager
  }

  func testFilterByParams() {
    let eventName = "restrictive_event_name"
    let parameters1 = [
      "dob": "06-29-2019"
    ]
    let expected1 = [
      "_restrictedParams": "{\"dob\":\"4\"}"
    ]
    let processedParameters1 = restrictiveDataFilterManager.processParameters(parameters1, eventName: eventName)

    XCTAssertEqual(processedParameters1 as? [String: String], expected1)

    let parameters2 = [
      "test_key": 66666
    ]
    let processedParameters2 = restrictiveDataFilterManager.processParameters(parameters2, eventName: eventName)

    XCTAssertEqual(processedParameters2 as? [String: NSNumber], parameters2 as [String: NSNumber])
  }

  func testGetMatchedDataTypeByParam() {
    let testEventName = "test_event_name"
    let type1 = restrictiveDataFilterManager.getMatchedDataType(
      withEventName: testEventName,
      paramKey: "first name"
    )
    XCTAssertEqual(type1, "6")

    let type2 = restrictiveDataFilterManager.getMatchedDataType(
      withEventName: testEventName,
      paramKey: "reservation number"
    )
    XCTAssertNil(type2)
  }

  func testProcessEventCanHandleAnEmptyArray() {
    XCTAssertNoThrow(restrictiveDataFilterManager.processEvents([]))
  }

  func testProcessEventCanHandleMissingKeys() {
    let event = [
      "some_event": [:]
    ]
    XCTAssertNoThrow(
      restrictiveDataFilterManager.processEvents([event]),
      "Data filter manager should be able to process events with missing keys"
    )
  }

  func testProcessEventDoesntReplaceEventNameIfNotRestricted() {
    let event = [
      "event": [
        "_eventName": NSNull()
      ]
    ]
    restrictiveDataFilterManager.processEvents([event])
    XCTAssertEqual(
      event["event"]?["_eventName"],
      NSNull(),
      "Non-restricted event names should not be replaced"
    )
  }
}
