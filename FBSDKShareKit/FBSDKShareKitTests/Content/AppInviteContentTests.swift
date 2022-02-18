/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import FBSDKShareKit
import XCTest

final class AppInviteContentTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional force_unwrapping
  var content: AppInviteContent!
  let appLinkURL = URL(string: "https://fb.me/1595011414049078")!
  let appInvitePreviewImageURL = URL(string: "https://fbstatic-a.akamaihd.net/rsrc.php/v2/y6/r/YQEGe6GxI_M.png")!
  // swiftlint:enable implicitly_unwrapped_optional force_unwrapping

  override func setUp() {
    super.setUp()

    content = AppInviteContent(appLinkURL: appLinkURL)
    content.appInvitePreviewImageURL = appInvitePreviewImageURL
  }

  func testProperties() {
    XCTAssertEqual(content.appLinkURL, appLinkURL)
    XCTAssertEqual(content.appInvitePreviewImageURL, appInvitePreviewImageURL)
  }

  func testValidationWithValidContent() throws {
    XCTAssertNoThrow(try content.validate(options: []))
  }

  func testValidationWithNilPreviewImageURL() {
    content = AppInviteContent(appLinkURL: appLinkURL)
    XCTAssertNoThrow(try content.validate(options: []))
  }

  func testValidationWithNilPromotionTextNilPromotionCode() {
    content = AppInviteContent(appLinkURL: appLinkURL)
    XCTAssertNoThrow(try content.validate(options: []))
  }

  func testValidationWithValidPromotionCodeNilPromotionText() {
    content.promotionCode = "XSKSK"

    XCTAssertThrowsError(
      try content.validate(options: []),
      "Should throw an error"
    ) { error in
      let nsError = error as NSError
      XCTAssertEqual(nsError.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(nsError.userInfo[ErrorArgumentNameKey] as? String, "promotionText")
    }
  }

  func testValidationWithValidPromotionTextNilPromotionCode() {
    content.promotionText = "Some Promo Text"
    XCTAssertNoThrow(try content.validate(options: []))
  }

  func testValidationWithBadPromotionTextLength() {
    content.promotionText = String(repeating: "_Invalid_promotionText", count: 30)

    XCTAssertThrowsError(
      try content.validate(options: []),
      "Should throw an error"
    ) { error in
      let nsError = error as NSError
      XCTAssertEqual(nsError.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(nsError.userInfo[ErrorArgumentNameKey] as? String, "promotionText")
    }
  }

  func testValidationWithBadPromotionTextContent() {
    content.promotionText = "_Invalid_promotionText"

    XCTAssertThrowsError(
      try content.validate(options: []),
      "Should throw an error"
    ) { error in
      let nsError = error as NSError
      XCTAssertEqual(nsError.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(nsError.userInfo[ErrorArgumentNameKey] as? String, "promotionText")
    }
  }

  func testValidationWithBadPromotionCodeLength() {
    content.promotionText = "Some promo text"
    content.promotionCode = "_invalid promo_code"

    XCTAssertThrowsError(
      try content.validate(options: []),
      "Should throw an error"
    ) { error in
      let nsError = error as NSError
      XCTAssertEqual(nsError.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(nsError.userInfo[ErrorArgumentNameKey] as? String, "promotionCode")
    }
  }

  func testValidationWithBadPromotionCodeContent() {
    content.promotionText = "Some promo text"
    content.promotionCode = "_invalid"

    XCTAssertThrowsError(
      try content.validate(options: []),
      "Should throw an error"
    ) { error in
      let nsError = error as NSError
      XCTAssertEqual(nsError.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(nsError.userInfo[ErrorArgumentNameKey] as? String, "promotionCode")
    }
  }
}
