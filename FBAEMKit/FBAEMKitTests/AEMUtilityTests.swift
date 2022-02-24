/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import XCTest

#if !os(tvOS)

final class AEMUtilityTests: XCTestCase {

  enum Keys {
    static let content = "fb_content"
    static let contentID = "fb_content_id"
    static let identity = "id"
    static let itemPrice = "item_price"
    static let quantity = "quantity"
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
    XCTAssertTrue(value.isEqual(to: NSNumber(value: 320)), "Don't get the expected in segment value")
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
    XCTAssertTrue(value.isEqual(to: NSNumber(value: 0)), "Don't get the expected in segment value")
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
    XCTAssertTrue(value.isEqual(to: NSNumber(value: 100)), "Don't get the expected in segment value")
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

  func getJsonString(object: [Any]) -> String {
    let jsonData = try? JSONSerialization.data(withJSONObject: object, options: [])
    return String(data: jsonData!, encoding: String.Encoding.ascii)! // swiftlint:disable:this force_unwrapping
  }
}

#endif
