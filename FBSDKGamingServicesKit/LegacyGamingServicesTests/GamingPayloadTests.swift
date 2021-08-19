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

class GamingPayloadTests: XCTestCase {

  func testGamePayloadWithValidValues() throws {
    let url = try SampleUnparsedAppLinkURLs.validGameRequestUrl()
    let appLink = AppLinkURL(url: url)
    let gamingPayload = GamingPayload(url: appLink)
    XCTAssertEqual("123", gamingPayload.gameRequestID)
    XCTAssertEqual("payload", gamingPayload.payload)
  }

  func testGamingPayloadWithNonAlphanumericStrings() throws {
    let url = try SampleUnparsedAppLinkURLs.create(payload: "{}{}{}", gameRequestID: "{}{}{}")
    let appLink = AppLinkURL(url: url)
    let gamingPayload = GamingPayload(url: appLink)
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
    let gamingPayload = GamingPayload(url: appLink)
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
    let gamingPayload = GamingPayload(url: appLink)
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
    let gamingPayload = GamingPayload(url: appLink)
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
    let gamingPayload = GamingPayload(url: appLink)
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
