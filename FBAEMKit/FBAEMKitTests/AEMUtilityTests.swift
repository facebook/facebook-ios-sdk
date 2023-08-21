/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBAEMKit
import Foundation
import XCTest

final class AEMUtilityTests: XCTestCase {
  enum Keys {
    static let content = "fb_content"
    static let contentID = "fb_content_id"
    static let identity = "id"
    static let itemPrice = "item_price"
    static let quantity = "quantity"
  }

  func testGetMatchedInvocationWithoutBusinessID() {
    let invocations = [SampleAEMInvocations.createGeneralInvocation1()]
    XCTAssertNil(
      AEMUtility.shared.getMatchedInvocation(invocations, businessID: "123"),
      "Should not expect to get the matched invocation without matched business ID"
    )
  }

  func testGetMatchedInvocationWithNullBusinessID() {
    let invocation = SampleAEMInvocations.createGeneralInvocation1()
    let invocations = [invocation, SampleAEMInvocations.createInvocationWithBusinessID()]
    XCTAssertEqual(
      invocation,
      AEMUtility.shared.getMatchedInvocation(invocations, businessID: nil),
      "Should expect to get the matched invocation without businessID"
    )
  }

  func testGetMatchedInvocationWithUnmatchedBusinessID() {
    let invocationWithBusinessID = SampleAEMInvocations.createInvocationWithBusinessID()
    let invocations = [invocationWithBusinessID, SampleAEMInvocations.createGeneralInvocation1()]
    XCTAssertNil(
      AEMUtility.shared.getMatchedInvocation(invocations, businessID: "123"),
      "Should not expect to get the matched invocation without matched business ID"
    )
  }

  func testGetMatchedInvocationWithMatchedBusinessID() {
    let invocationWithBusinessID = SampleAEMInvocations.createInvocationWithBusinessID()
    let invocations = [invocationWithBusinessID, SampleAEMInvocations.createGeneralInvocation1()]
    XCTAssertEqual(
      invocationWithBusinessID,
      AEMUtility.shared.getMatchedInvocation(invocations, businessID: invocationWithBusinessID.businessID),
      "Should expect to get the matched invocation"
    )
  }

  func testGetInSegmentValue() {
    let parameters = [
      Keys.content: [
        [
          Keys.identity: "12345",
          Keys.itemPrice: NSNumber(value: 10),
          Keys.quantity: NSNumber(value: 2),
        ],
        [
          Keys.identity: "12345",
          Keys.itemPrice: NSNumber(value: 100),
          Keys.quantity: NSNumber(value: 3),
        ],
        [
          Keys.identity: "testing",
          Keys.itemPrice: NSNumber(value: 100),
          Keys.quantity: NSNumber(value: 2),
        ],
      ],
    ]

    let value = AEMUtility.shared.getInSegmentValue(parameters, matchingRule: SampleAEMMultiEntryRules.contentRule)
    XCTAssertEqual(value.intValue, 320, "Didn't get the expected in-segment value")
  }

  func testGetInSegmentValueWithDefaultPrice() {
    let parameters = [
      Keys.content: [
        [
          Keys.identity: "12345",
          Keys.quantity: NSNumber(value: 2),
        ],
      ],
    ]

    let value = AEMUtility.shared.getInSegmentValue(parameters, matchingRule: SampleAEMMultiEntryRules.contentRule)
    XCTAssertEqual(value.intValue, 0, "Didn't get the expected in-segment value")
  }

  func testGetInSegmentValueWithDefaultQuantity() {
    let parameters = [
      Keys.content: [
        [
          Keys.identity: "12345",
          Keys.itemPrice: NSNumber(value: 100),
        ],
      ],
    ]

    let value = AEMUtility.shared.getInSegmentValue(parameters, matchingRule: SampleAEMMultiEntryRules.contentRule)
    XCTAssertEqual(value.intValue, 100, "Didn't get the expected in-segment value")
  }

  func testGetContent() {
    let content = AEMUtility.shared.getContent([
      Keys.content: getJsonString(object: [
        [Keys.identity: "123"],
        [Keys.identity: "456"],
      ]),
    ])
    XCTAssertEqual(content, #"[{"id":"123"},{"id":"456"}]"#)
  }

  func testGetContentWithoutData() {
    let content = AEMUtility.shared.getContent([
      Keys.contentID: getJsonString(object: [
        [Keys.identity: "123"],
        [Keys.identity: "456"],
      ]),
    ])
    XCTAssertNil(content)
  }

  func testGetContentWithIntID() {
    let contentID = AEMUtility.shared.getContentID([
      Keys.content: getJsonString(object: [
        [Keys.identity: NSNumber(value: 123)],
        [Keys.identity: NSNumber(value: 456)],
      ]),
    ])
    XCTAssertEqual(contentID, #"["123","456"]"#)
  }

  func testGetContentWithStringID() {
    let contentID = AEMUtility.shared.getContentID([
      Keys.content: getJsonString(object: [
        [Keys.identity: "123"],
        [Keys.identity: "456"],
      ]),
    ])
    XCTAssertEqual(contentID, #"["123","456"]"#)
  }

  func testGetContentFallback() {
    let contentID = AEMUtility.shared.getContentID([
      Keys.contentID: #"["123","456"]"#,
    ])
    XCTAssertEqual(contentID, #"["123","456"]"#)
  }

  func testGetBusinessIDsInOrderWithoutInvocations() {
    let businessIDs = AEMUtility.shared.getBusinessIDsInOrder([])
    XCTAssertEqual(businessIDs, [])
  }

  func testGetBusinessIDsInOrderWithoutBusinessIDs() {
    let businessIDs = AEMUtility.shared.getBusinessIDsInOrder(
      [
        SampleAEMInvocations.createGeneralInvocation1(),
        SampleAEMInvocations.createGeneralInvocation2(),
      ]
    )
    XCTAssertEqual(businessIDs, ["", ""])
  }

  func testGetBusinessIDsInOrderWithBusinessIDs() {
    let invocation = SampleAEMInvocations.createInvocationWithBusinessID()
    let businessIDs = AEMUtility.shared.getBusinessIDsInOrder(
      [
        SampleAEMInvocations.createGeneralInvocation1(),
        SampleAEMInvocations.createGeneralInvocation2(),
        invocation,
      ]
    )
    XCTAssertEqual(businessIDs, [invocation.businessID, "", ""])
  }

  func getJsonString(object: [Any]) -> String {
    let jsonData = try? JSONSerialization.data(withJSONObject: object, options: [])
    return String(data: jsonData!, encoding: String.Encoding.ascii)! // swiftlint:disable:this force_unwrapping
  }
}
