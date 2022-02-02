/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit

import FBSDKCoreKit
import XCTest

final class GamingPayloadTests: XCTestCase {

  func testGamePayloadWithValidValues() throws {
    let url = try SampleUnparsedAppLinkURLs.validGameRequestUrl()
    let appLink = AppLinkURL(url: url)
    let gamingPayload = GamingPayload(URL: appLink)
    XCTAssertEqual("123", gamingPayload.gameRequestID)
    XCTAssertEqual("payload", gamingPayload.payload)
  }

  func testGamingPayloadWithNonAlphanumericStrings() throws {
    let url = try SampleUnparsedAppLinkURLs.create(payload: "{}{}{}", gameRequestID: "{}{}{}")
    let appLink = AppLinkURL(url: url)
    let gamingPayload = GamingPayload(URL: appLink)
    XCTAssertEqual(
      "{}{}{}",
      gamingPayload.gameRequestID,
      "Should be able to return a gameRequestID with non alphanumeric values"
    )
    XCTAssertEqual(
      "{}{}{}",
      gamingPayload.payload,
      "Should be able to return a payload with non alphanumeric values"
    )
  }

  func testGamingPayloadWithNilInPayload() throws {
    let url = try SampleUnparsedAppLinkURLs.create(payload: nil)
    let appLink = AppLinkURL(url: url)
    let gamingPayload = GamingPayload(URL: appLink)
    XCTAssertEqual(
      "123",
      gamingPayload.gameRequestID,
      "Should be able to return a gameRequestID with nil payload"
    )
    XCTAssertEqual("", gamingPayload.payload)
  }

  func testGamingPayloadWithNilInGameRequestID() throws {
    let url = try SampleUnparsedAppLinkURLs.create(gameRequestID: nil)
    let appLink = AppLinkURL(url: url)
    let gamingPayload = GamingPayload(URL: appLink)
    XCTAssertEqual("", gamingPayload.gameRequestID)
    XCTAssertEqual(
      "payload",
      gamingPayload.payload,
      "Should be able to return a payload with nil gameRequestID"
    )
  }

  func testGamingPayloadWithBothParamsNil() throws {
    let url = try SampleUnparsedAppLinkURLs.missingKeys()
    let appLink = AppLinkURL(url: url)
    let gamingPayload = GamingPayload(URL: appLink)
    XCTAssertEqual(
      "",
      gamingPayload.gameRequestID,
      "Should be able to return an empty payload with both nil params"
    )
    XCTAssertEqual(
      "",
      gamingPayload.payload,
      "Should be able to return an empty payload with both nil params"
    )
  }

  func testGamingPayloadWithExtraSpaceInString() throws {
    let url = try SampleUnparsedAppLinkURLs.create(
      payload: "  ",
      gameRequestID: "  "
    )
    let appLink = AppLinkURL(url: url)
    let gamingPayload = GamingPayload(URL: appLink)
    XCTAssertEqual(
      "  ",
      gamingPayload.gameRequestID,
      "Should be able to return a string with extra space in gameRequestID"
    )
    XCTAssertEqual(
      "  ",
      gamingPayload.payload,
      "Should be able to return a string with extra space in payload"
    )
  }
}
