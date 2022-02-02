/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import XCTest

@available(iOS 13.0, *)
final class CustomUpdateContentTests: XCTestCase {

  var validMessage = "text"
  var contextToken = "12345"
  var ctaText = "play"
  var payload = "data123"
  var localization = ["data123": "test"]

  var gif = FacebookGIF(withUrl: URL(string: "www.test.com")!) // swiftlint:disable:this force_unwrapping
  var validImage = UIImage(
    named: "customColorSilhouette",
    in: Bundle(for: CustomUpdateContentTests.self),
    with: nil
  )! // swiftlint:disable:this force_unwrapping

  func testCustomUpdateContentMediaInitWithOnlyRequiredValues() throws {
    let content = try XCTUnwrap(CustomUpdateContentMedia(
      message: validMessage,
      media: gif
    ))

    XCTAssertEqual(validMessage, content.message)
    XCTAssertEqual(gif, content.media as? FacebookGIF)
  }

  func testCustomUpdateContentMediaInitWithAllValues() throws {
    let content = try XCTUnwrap(CustomUpdateContentMedia(
      message: validMessage,
      media: gif,
      cta: ctaText,
      payload: payload,
      messageLocalization: localization,
      ctaLocalization: localization
    ))

    XCTAssertEqual(validMessage, content.message)
    XCTAssertEqual(gif, content.media as? FacebookGIF)
    XCTAssertEqual(ctaText, content.ctaText)
    XCTAssertEqual(payload, content.payload)
    XCTAssertEqual(localization, content.messageLocalization)
    XCTAssertEqual(localization, content.ctaLocalization)
  }

  func testCustomUpdateContentImageInitWithOnlyRequiredValues() throws {
    let content = try XCTUnwrap(CustomUpdateContentImage(
      message: validMessage,
      image: validImage
    ))

    XCTAssertEqual(validMessage, content.message)
    XCTAssertEqual(validImage, content.image)
  }

  func testCustomUpdateContentImageInitWithAllValues() throws {
    let content = try XCTUnwrap(CustomUpdateContentImage(
      message: validMessage,
      image: validImage,
      cta: ctaText,
      payload: payload,
      messageLocalization: localization,
      ctaLocalization: localization
    ))

    XCTAssertEqual(validMessage, content.message)
    XCTAssertEqual(validImage, content.image)
    XCTAssertEqual(ctaText, content.ctaText)
    XCTAssertEqual(payload, content.payload)
    XCTAssertEqual(localization, content.messageLocalization)
    XCTAssertEqual(localization, content.ctaLocalization)
  }
}
