/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class RestrictiveDataFilterTests: XCTestCase {
  var restrictiveDataFilterManager: RestrictiveDataFilterManager = createTestRestrictiveDataFilterManager()

  private static func createTestRestrictiveDataFilterManager() -> RestrictiveDataFilterManager {
    let params = [
      "test_event_name": [
        "restrictive_param": [
          "first name": "6",
          "last name": "7",
        ],
      ],
      "restrictive_event_name": [
        "restrictive_param": [
          "dob": 4,
        ],
      ],
    ]
    let configuration = ServerConfigurationFixtures.configuration(withDictionary: [
      "restrictiveParams": params,
    ])
    let serverConfigProider = TestServerConfigurationProvider(configuration: configuration)
    let restrictiveDataFilterManager = RestrictiveDataFilterManager(serverConfigurationProvider: serverConfigProider)
    restrictiveDataFilterManager.enable()
    return restrictiveDataFilterManager
  }

  func testFilterByParams() throws {
    let eventName = AppEvents.Name("restrictive_event_name")
    let parameters1: [AppEvents.ParameterName: Any] = [
      .init("dob"): "06-29-2019",
    ]
    let expected1: [AppEvents.ParameterName: String] = [
      .init("_restrictedParams"): #"{"dob":"4"}"#,
    ]
    let processedParameters1 = restrictiveDataFilterManager.processParameters(parameters1, eventName: eventName)

    XCTAssertEqual(processedParameters1 as? [AppEvents.ParameterName: String], expected1)

    let parameters2: [AppEvents.ParameterName: Any] = [
      .init("test_key"): 66666,
    ]
    let processedParameters2 = try XCTUnwrap(
      restrictiveDataFilterManager.processParameters(
        parameters2,
        eventName: eventName
      ) as? [AppEvents.ParameterName: Int]
    )

    XCTAssertEqual(
      processedParameters2,
      parameters2 as? [AppEvents.ParameterName: Int]
    )
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
      "some_event": [:],
    ]
    XCTAssertNoThrow(
      restrictiveDataFilterManager.processEvents([event]),
      "Data filter manager should be able to process events with missing keys"
    )
  }

  func testProcessEventDoesntReplaceEventNameIfNotRestricted() {
    let event = [
      "event": [
        "_eventName": NSNull(),
      ],
    ]
    restrictiveDataFilterManager.processEvents([event])
    XCTAssertEqual(
      event["event"]?["_eventName"],
      NSNull(),
      "Non-restricted event names should not be replaced"
    )
  }
}
