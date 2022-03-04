/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

import FBSDKCoreKit
import TestTools
import XCTest

final class AppInviteContentTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional force_unwrapping
  var content: AppInviteContent!
  let appLinkURL = URL(string: "https://fb.me/1595011414049078")!
  let appInvitePreviewImageURL = URL(string: "https://fbstatic-a.akamaihd.net/rsrc.php/v2/y6/r/YQEGe6GxI_M.png")!
  var validator: TestShareUtility.Type!
  var errorFactory: TestErrorFactory!
  // swiftlint:enable implicitly_unwrapped_optional force_unwrapping

  override func setUp() {
    super.setUp()

    validator = TestShareUtility.self
    validator.reset()
    errorFactory = TestErrorFactory()

    AppInviteContent.setDependencies(
      .init(
        validator: validator,
        errorFactory: errorFactory
      )
    )

    content = AppInviteContent(appLinkURL: appLinkURL)
    content.appInvitePreviewImageURL = appInvitePreviewImageURL
  }

  override func tearDown() {
    AppInviteContent.resetDependencies()

    validator.reset()
    validator = nil
    errorFactory = nil
    content = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    AppInviteContent.resetDependencies()

    let dependencies = try AppInviteContent.getDependencies()
    XCTAssertTrue(dependencies.validator is _ShareUtility.Type, .usesShareUtilityByDefault)
    XCTAssertTrue(dependencies.errorFactory is ErrorFactory, .usesErrorFactoryByDefault)
  }

  func testCustomDependencies() throws {
    let dependencies = try AppInviteContent.getDependencies()
    XCTAssertTrue(dependencies.validator is TestShareUtility.Type, .usesCustomShareValidator)
    XCTAssertIdentical(dependencies.errorFactory as AnyObject, errorFactory, .usesCustomErrorFactory)
  }

  func testProperties() {
    XCTAssertEqual(content.appLinkURL, appLinkURL, .hasAppLinkURL)
    XCTAssertEqual(content.appInvitePreviewImageURL, appInvitePreviewImageURL, .hasAppInvitePreviewImageURL)
  }

  func testValidationWithValidContent() throws {
    XCTAssertNoThrow(try content.validate(options: []), .passesValidationWithValidContent)
  }

  func testValidationWithNilPreviewImageURL() {
    content = AppInviteContent(appLinkURL: appLinkURL)
    XCTAssertNoThrow(try content.validate(options: []), .passesValidationWithoutPreviewImageURL)
  }

  func testValidationWithNilPromotionTextNilPromotionCode() {
    content = AppInviteContent(appLinkURL: appLinkURL)
    XCTAssertNoThrow(try content.validate(options: []), .passesValidationWithoutPromotionTextAndPromotionCode)
  }

  func testValidationWithValidPromotionCodeNilPromotionText() {
    content.promotionCode = "XSKSK"

    XCTAssertThrowsError(
      try content.validate(options: []),
      .failsValidationWithPromotionCodeOnly
    ) { error in
      guard let sdkError = error as? TestSDKError else {
        return XCTFail(.failsValidationWithPromotionCodeOnly)
      }

      XCTAssertEqual(sdkError.type, .invalidArgument, .failsValidationWithPromotionCodeOnly)
      XCTAssertEqual(sdkError.name, "promotionText", .failsValidationWithPromotionCodeOnly)
      XCTAssertEqual(sdkError.value as? String, content.promotionText, .failsValidationWithPromotionCodeOnly)
      XCTAssertEqual(
        sdkError.message,
        "Invalid value for promotionText; promotionText has to be between 1 and 80 characters long.",
        .failsValidationWithPromotionCodeOnly
      )
      XCTAssertNil(sdkError.underlyingError, .failsValidationWithPromotionCodeOnly)
    }
  }

  func testValidationWithValidPromotionTextNilPromotionCode() {
    content.promotionText = "Some Promo Text"
    XCTAssertNoThrow(try content.validate(options: []), .failsValidationWithPromotionTextOnly)
  }

  func testValidationWithBadPromotionTextLength() {
    content.promotionText = String(repeating: "_Invalid_promotionText", count: 30)

    XCTAssertThrowsError(
      try content.validate(options: []),
      .failsValidationWithShortPromotionText
    ) { error in
      guard let sdkError = error as? TestSDKError else {
        return XCTFail(.failsValidationWithShortPromotionText)
      }

      XCTAssertEqual(sdkError.type, .invalidArgument, .failsValidationWithShortPromotionText)
      XCTAssertEqual(sdkError.name, "promotionText", .failsValidationWithShortPromotionText)
      XCTAssertEqual(sdkError.value as? String, content.promotionText, .failsValidationWithShortPromotionText)
      XCTAssertEqual(
        sdkError.message,
        "Invalid value for promotionText; promotionText has to be between 1 and 80 characters long.",
        .failsValidationWithShortPromotionText
      )
      XCTAssertNil(sdkError.underlyingError, .failsValidationWithShortPromotionText)
    }
  }

  func testValidationWithBadPromotionTextContent() {
    content.promotionText = "_Invalid_promotionText"

    XCTAssertThrowsError(
      try content.validate(options: []),
      .failsValidationWithBadPromotionTextContent
    ) { error in
      guard let sdkError = error as? TestSDKError else {
        return XCTFail(.failsValidationWithBadPromotionTextContent)
      }

      XCTAssertEqual(sdkError.type, .invalidArgument, .failsValidationWithBadPromotionTextContent)
      XCTAssertEqual(sdkError.name, "promotionText", .failsValidationWithBadPromotionTextContent)
      XCTAssertEqual(sdkError.value as? String, content.promotionText, .failsValidationWithBadPromotionTextContent)
      XCTAssertEqual(
        sdkError.message,
        "Invalid value for promotionText; promotionText can contain only alphanumeric characters and spaces.",
        .failsValidationWithBadPromotionTextContent
      )
      XCTAssertNil(sdkError.underlyingError, .failsValidationWithBadPromotionTextContent)
    }
  }

  func testValidationWithBadPromotionCodeLength() {
    content.promotionText = "Some promo text"
    content.promotionCode = "_invalid promo_code"

    XCTAssertThrowsError(
      try content.validate(options: []),
      .failsValidationWithShortPromotionCode
    ) { error in
      guard let sdkError = error as? TestSDKError else {
        return XCTFail(.failsValidationWithShortPromotionCode)
      }

      XCTAssertEqual(sdkError.type, .invalidArgument, .failsValidationWithShortPromotionCode)
      XCTAssertEqual(sdkError.name, "promotionCode", .failsValidationWithShortPromotionCode)
      XCTAssertEqual(sdkError.value as? String, content.promotionCode, .failsValidationWithShortPromotionCode)
      XCTAssertEqual(
        sdkError.message,
        """
        Invalid value for promotionCode; promotionCode has to be between 0 and 10 characters long \
        and is required when promoCode is set.
        """,
        .failsValidationWithShortPromotionCode
      )
      XCTAssertNil(sdkError.underlyingError, .failsValidationWithShortPromotionCode)
    }
  }

  func testValidationWithBadPromotionCodeContent() {
    content.promotionText = "Some promo text"
    content.promotionCode = "_invalid"

    XCTAssertThrowsError(
      try content.validate(options: []),
      .failsValidationWithBadPromotionCode
    ) { error in
      guard let sdkError = error as? TestSDKError else {
        return XCTFail(.failsValidationWithBadPromotionCode)
      }

      XCTAssertEqual(sdkError.type, .invalidArgument, .failsValidationWithBadPromotionCode)
      XCTAssertEqual(sdkError.name, "promotionCode", .failsValidationWithBadPromotionCode)
      XCTAssertEqual(sdkError.value as? String, content.promotionCode, .failsValidationWithBadPromotionCode)
      XCTAssertEqual(
        sdkError.message,
        "Invalid value for promotionCode; promotionCode can contain only alphanumeric characters and spaces.",
        .failsValidationWithBadPromotionCode
      )
      XCTAssertNil(sdkError.underlyingError, .failsValidationWithBadPromotionCode)
    }
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let usesErrorFactoryByDefault = "The default error factory dependency should be a concrete ErrorFactory"
  static let usesShareUtilityByDefault = "The default share validator dependency should be the _ShareUtility type"
  static let usesCustomErrorFactory = "The error factory dependency should be configurable"
  static let usesCustomShareValidator = "The share validator dependency should be configurable"

  static let hasAppLinkURL = "An app invite content has an app link URL"
  static let hasAppInvitePreviewImageURL = "An app invite content has an invite preview image URL"

  static let passesValidationWithValidContent = "Validation should pass with valid content"
  static let passesValidationWithoutPreviewImageURL = "Validation should pass without a preview image URL"
  static let passesValidationWithoutPromotionTextAndPromotionCode = """
    Validation should pass when missing both promotion text and promotion code
    """
  static let failsValidationWithPromotionCodeOnly = "Validation should fail with only a promotion code"
  static let failsValidationWithPromotionTextOnly = "Validation should fail with only promotion text"
  static let failsValidationWithShortPromotionText = "Validation should fail with promotion text that is too short"
  static let failsValidationWithBadPromotionTextContent = "Validation should fail with invalid promotion text content"
  static let failsValidationWithShortPromotionCode = "Validation should fail with a promotion code that is too short"
  static let failsValidationWithBadPromotionCode = "Validation should fail with invalid promotion code content"
}
