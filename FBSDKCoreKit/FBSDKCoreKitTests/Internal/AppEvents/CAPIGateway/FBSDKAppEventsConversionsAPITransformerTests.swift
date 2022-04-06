/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
import XCTest

class FBSDKAppEventsConversionsAPITransformerTests: XCTestCase {

  // MARK: Helper variables

  let customEvent1 = "[{\"_eventName\":\"fb_mobile_add_to_cart\",\"_logTime\":12345}]"
  let customEvent2 =
  "[{\"_eventName\":\"fb_mobile_add_to_cart\",\"_logTime\":12345}, {\"_eventName\":\"new_event\",\"_logTime\":67890, \"fb_content_type\":\"product\", \"_valueToSum\":21.97, \"fb_currency\":\"GBP\"}]"

  let ud = "{\"fn\":\"1234567890\", \"em\":\"ABCDE\"}"

  let restOfData1 = [
    AppEventsConversionsAPITransformer.DataProcessingParameterName.options.rawValue: 1,
    AppEventsConversionsAPITransformer.DataProcessingParameterName.state.rawValue: 0,
  ] as [String: Any]

  let transformedAppData1 = [
    AppEventUserAndAppDataField.advTE.rawValue: 1,
    AppEventUserAndAppDataField.extinfo.rawValue: ["i2"],
  ] as [String: Any]

  let transformedUserData1 = [
    ConversionsAPIUserAndAppDataField.madid.rawValue: "ABCDE-12345",
    "fn": "1234567890",
    "em": "ABCDE",
  ] as [String: String]

  let transformedCustomEvent1 = [
    ConversionsAPICustomEventField.eventName.rawValue: ConversionsAPIEventName.addToCart.rawValue,
    ConversionsAPICustomEventField.eventTime.rawValue: 12345,
  ] as [String: Any]

  let transformedCustomEvent2 = [
    ConversionsAPICustomEventField.eventName.rawValue: "new_event",
    ConversionsAPICustomEventField.eventTime.rawValue: 67890,
    ConversionsAPISection.customData.rawValue: [
      ConversionsAPICustomEventField.contentType.rawValue: "product",
      ConversionsAPICustomEventField.valueToSum.rawValue: 21.97,
      ConversionsAPICustomEventField.currency.rawValue: "GBP",
    ],
  ] as [String: Any]

  // MARK: Helper functions

  func checkIfCommonFieldsAreEqual(parameters: [String: Any]) throws {
    let userData = try XCTUnwrap(parameters[ConversionsAPISection.userData.rawValue] as? [String: String])
    XCTAssertEqual(userData, transformedUserData1)

    let appData = try XCTUnwrap(parameters[ConversionsAPISection.appData.rawValue] as? [String: Any])

    let ATE = try XCTUnwrap(appData[ConversionsAPIUserAndAppDataField.advTE.rawValue] as? Int)
    let extinfo = try XCTUnwrap(appData[ConversionsAPIUserAndAppDataField.extinfo.rawValue] as? [Any])
    XCTAssertEqual(ATE, 1)
    XCTAssertEqual(extinfo.count, 1)
    XCTAssertEqual(extinfo[0] as? String, "i2")
    let actionSource = try XCTUnwrap(parameters[OtherEventConstants.actionSource.rawValue] as? String)
    XCTAssertEqual(actionSource, OtherEventConstants.app.rawValue)

    let options = try XCTUnwrap(
      parameters[AppEventsConversionsAPITransformer.DataProcessingParameterName.options.rawValue] as? Int)
    let state = try XCTUnwrap(
      parameters[AppEventsConversionsAPITransformer.DataProcessingParameterName.state.rawValue] as? Int)
    XCTAssertEqual(options, 1)
    XCTAssertEqual(state, 0)
  }

  func checkIfMAIEventIsEqual(parameters: [String: Any]) throws {
    let eventName = try XCTUnwrap(parameters[ConversionsAPICustomEventField.eventName.rawValue] as? String)
    let eventTime = try XCTUnwrap(parameters[ConversionsAPICustomEventField.eventTime.rawValue] as? Int)
    XCTAssertEqual(eventName, OtherEventConstants.mobileAppInstall.rawValue)
    XCTAssertEqual(eventTime, 23456)
  }

  func checkIfCustomEvent1IsEqual(parameters: [String: Any]) throws {
    let eventName = try XCTUnwrap(parameters[ConversionsAPICustomEventField.eventName.rawValue] as? String)
    let eventTime = try XCTUnwrap(parameters[ConversionsAPICustomEventField.eventTime.rawValue] as? Int)

    XCTAssertEqual(eventName, "AddToCart")
    XCTAssertEqual(eventTime, 12345)
  }

  func checkIfCustomEvent2IsEqual(parameters: [String: Any]) throws {
    let eventName = try XCTUnwrap(parameters[ConversionsAPICustomEventField.eventName.rawValue] as? String)
    let eventTime = try XCTUnwrap(parameters[ConversionsAPICustomEventField.eventTime.rawValue] as? Int)
    let customData1 = try XCTUnwrap(parameters[ConversionsAPISection.customData.rawValue] as? [String: Any])
    let contentType = try XCTUnwrap(customData1[ConversionsAPICustomEventField.contentType.rawValue] as? String)
    let valueToSum = try XCTUnwrap(customData1[ConversionsAPICustomEventField.valueToSum.rawValue] as? Double)
    let currency = try XCTUnwrap(customData1[ConversionsAPICustomEventField.currency.rawValue] as? String)

    XCTAssertEqual(eventName, "new_event")
    XCTAssertEqual(eventTime, 67890)
    XCTAssertEqual(contentType, "product")
    XCTAssertEqual(valueToSum, 21.97)
    XCTAssertEqual(currency, "GBP")
  }

  // MARK: Tests

  func testTransformEvents() throws {
    let events = "[{\"_eventName\":\"fb_mobile_add_to_cart\",\"_logTime\":12345}]"
    let transformedEvents = AppEventsConversionsAPITransformer.transformEvents(from: events)
    XCTAssertEqual(transformedEvents?.count, 1)
    let firstEvent = try XCTUnwrap(transformedEvents?[0])
    try checkIfCustomEvent1IsEqual(parameters: firstEvent)
  }

  func testTransformMultipleEvents() throws {
    let transformedEvents = AppEventsConversionsAPITransformer.transformEvents(from: customEvent2)

    XCTAssertEqual(transformedEvents?.count, 2)
    let firstEvent = try XCTUnwrap(transformedEvents?[0])
    try checkIfCustomEvent1IsEqual(parameters: firstEvent)

    let secondEvent = try XCTUnwrap(transformedEvents?[1])
    try checkIfCustomEvent2IsEqual(parameters: secondEvent)
  }

  func testTransformAndUpdateAppAndUserData() throws {
    var userData = [String: Any]()
    var appData = [String: Any]()

    AppEventsConversionsAPITransformer.transformAndUpdateAppAndUserData(
      userData: &userData, appData: &appData, field: AppEventUserAndAppDataField.advertiserId, value: "ABCDE-12345")
    AppEventsConversionsAPITransformer.transformAndUpdateAppAndUserData(
      userData: &userData, appData: &appData, field: AppEventUserAndAppDataField.advTE, value: 1)
    AppEventsConversionsAPITransformer.transformAndUpdateAppAndUserData(
      userData: &userData, appData: &appData, field: AppEventUserAndAppDataField.extinfo, value: ["i2"])
    AppEventsConversionsAPITransformer.transformAndUpdateAppAndUserData(
      userData: &userData, appData: &appData, field: AppEventUserAndAppDataField.userData,
      value: "{\"fn\":\"1234567890\", \"em\":\"ABCDE\"}")

    let ATE = try XCTUnwrap(appData[ConversionsAPIUserAndAppDataField.advTE.rawValue] as? Int)
    let extinfo = try XCTUnwrap(appData[ConversionsAPIUserAndAppDataField.extinfo.rawValue] as? [Any])
    let madid = try XCTUnwrap(userData[ConversionsAPIUserAndAppDataField.madid.rawValue] as? String)
    let fn = try XCTUnwrap(userData["fn"] as? String)
    let em = try XCTUnwrap(userData["em"] as? String)

    XCTAssertEqual(ATE, 1)
    XCTAssertEqual(extinfo.count, 1)
    XCTAssertEqual(extinfo[0] as? String, "i2")
    XCTAssertEqual(madid, "ABCDE-12345")
    XCTAssertEqual(fn, "1234567890")
    XCTAssertEqual(em, "ABCDE")
  }

  func testTransformValueContents() throws {
    let transformedValue = AppEventsConversionsAPITransformer.transformValue(
      field: CustomEventField.contents.rawValue,
      value: "[{\"id\": \"1234\", \"quantity\": 1,},{\"id\":\"5678\", \"quantity\": 2,}]"
    ) as? [[String: Any]]
    XCTAssertEqual(transformedValue?.count, 2)

    var dict = try XCTUnwrap(transformedValue?[0])
    XCTAssertEqual(dict["id"] as? String, "1234")
    XCTAssertEqual(dict["quantity"] as? Int, 1)

    dict = try XCTUnwrap(transformedValue?[1])

    XCTAssertEqual(dict["id"] as? String, "5678")
    XCTAssertEqual(dict["quantity"] as? Int, 2)
  }

  func testTransformValueATE() throws {
    let ateTransformedValue = AppEventsConversionsAPITransformer.transformValue(
      field: AppEventUserAndAppDataField.advTE.rawValue,
      value: "1"
    ) as? Bool

    XCTAssertEqual(ateTransformedValue, true)
  }

  func testTransformValueExtinfo() throws {
    let transformedValue = AppEventsConversionsAPITransformer.transformValue(
      field: AppEventUserAndAppDataField.extinfo.rawValue,
      value: "[\"i0\", [\"i1\"], [\"i2\"]]"
    ) as? [Any]

    XCTAssertEqual(transformedValue?.count, 3)
    XCTAssertEqual(transformedValue?[0] as? String, "i0")
  }

  func testTransformValueEventTime() throws {
    var eventTime = AppEventsConversionsAPITransformer.transformValue(
      field: CustomEventField.eventTime.rawValue,
      value: 12345
    ) as? Int
    XCTAssertEqual(eventTime, 12345)

    eventTime = AppEventsConversionsAPITransformer.transformValue(
      field: CustomEventField.eventTime.rawValue,
      value: "12345"
    ) as? Int
    XCTAssertEqual(eventTime, 12345)

    eventTime = AppEventsConversionsAPITransformer.transformValue(
      field: CustomEventField.eventTime.rawValue,
      value: "abcd"
    ) as? Int
    XCTAssertNil(eventTime)
  }

  func testCombineCommonFields() throws {
    let combinedFields = AppEventsConversionsAPITransformer.combineCommonFields(
      userData: transformedUserData1,
      appData: transformedAppData1,
      restOfData: restOfData1)
    try checkIfCommonFieldsAreEqual(parameters: combinedFields)
  }

  func testCombineAllTransformedData1() throws {
    let transformedEvents = AppEventsConversionsAPITransformer.combineAllTransformedData(
      eventType: AppEventType.mobileAppInstall,
      userData: transformedUserData1,
      appData: transformedAppData1,
      restOfData: restOfData1,
      customEvents: [[String: Any]](),
      eventTime: 23456)
    XCTAssertEqual(transformedEvents?.count, 1)

    let firstEvent = try XCTUnwrap(transformedEvents?[0])

    try checkIfCommonFieldsAreEqual(parameters: firstEvent)
    try checkIfMAIEventIsEqual(parameters: firstEvent)
  }

  func testCombineAllTransformedData2() throws {
    let customEvents = [transformedCustomEvent1, transformedCustomEvent2]

    let transformedEvents = AppEventsConversionsAPITransformer.combineAllTransformedData(
      eventType: AppEventType.custom,
      userData: transformedUserData1,
      appData: transformedAppData1,
      restOfData: restOfData1,
      customEvents: customEvents,
      eventTime: nil)
    XCTAssertEqual(transformedEvents?.count, 2)

    let firstEvent = try XCTUnwrap(transformedEvents?[0])
    try checkIfCommonFieldsAreEqual(parameters: firstEvent)
    try checkIfCustomEvent1IsEqual(parameters: firstEvent)

    let secondEvent = try XCTUnwrap(transformedEvents?[1])
    try checkIfCommonFieldsAreEqual(parameters: secondEvent)
    try checkIfCustomEvent2IsEqual(parameters: secondEvent)
  }

  func testCombineAllTransformedDataCheckForNulls() {
    let customEvents = [transformedCustomEvent1, transformedCustomEvent2]

    XCTAssertNil(AppEventsConversionsAPITransformer.combineAllTransformedData(
      eventType: AppEventType.other, userData: transformedUserData1, appData: transformedAppData1,
      restOfData: restOfData1, customEvents: customEvents, eventTime: nil))
    XCTAssertNil(AppEventsConversionsAPITransformer.combineAllTransformedData(
      eventType: AppEventType.custom, userData: transformedUserData1, appData: transformedAppData1,
      restOfData: restOfData1, customEvents: [[String: Any]](), eventTime: nil))
    XCTAssertNil(AppEventsConversionsAPITransformer.combineAllTransformedData(
      eventType: AppEventType.mobileAppInstall, userData: transformedUserData1, appData: transformedAppData1,
      restOfData: restOfData1, customEvents: [[String: Any]](), eventTime: nil))
  }

  func testConversionsAPICompatibleEvent1() throws {
    var parameters = [
      "event": "MOBILE_APP_INSTALL",
      "advertiser_id": "ABCDE-12345",
      "advertiser_tracking_enabled": 1,
      "ud": ud,
      "extinfo": ["i2"],
      "install_timestamp": 23456,
    ] as [String: Any]
    parameters.merge(restOfData1) { $1 }

    let transformedEvents = AppEventsConversionsAPITransformer.conversionsAPICompatibleEvent(from: parameters)
    XCTAssertEqual(transformedEvents?.count, 1)
    let firstEvent = try XCTUnwrap(transformedEvents?[0])
    try checkIfCommonFieldsAreEqual(parameters: firstEvent)
    try checkIfMAIEventIsEqual(parameters: firstEvent)
  }

  func testConversionsAPICompatibleEvent2() throws {
    var parameters = [
      "event": "CUSTOM_APP_EVENTS",
      "advertiser_id": "ABCDE-12345",
      "advertiser_tracking_enabled": 1,
      "ud": ud,
      "extinfo": ["i2"],
      "custom_events": customEvent2,
    ] as [String: Any]
    parameters.merge(restOfData1) { $1 }

    let transformedEvents = AppEventsConversionsAPITransformer.conversionsAPICompatibleEvent(from: parameters)
    XCTAssertEqual(transformedEvents?.count, 2)
    let secondEvent = try XCTUnwrap(transformedEvents?[1])

    try checkIfCommonFieldsAreEqual(parameters: secondEvent)
    try checkIfCustomEvent2IsEqual(parameters: secondEvent)
  }
}
