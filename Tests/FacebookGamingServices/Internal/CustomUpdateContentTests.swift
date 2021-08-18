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

@testable import FacebookGamingServices
import XCTest

@available(iOS 13.0, *)
class CustomUpdateContentTests: XCTestCase {

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
      contextTokenID: contextToken,
      message: validMessage,
      media: gif
    ))

    XCTAssertEqual(content.contextTokenID, contextToken)
    XCTAssertEqual(validMessage, content.message)
    XCTAssertEqual(gif, content.media as? FacebookGIF)
  }

  func testCustomUpdateContentMediaInitWithAllValues() throws {
    let content = try XCTUnwrap(CustomUpdateContentMedia(
      contextTokenID: contextToken,
      message: validMessage,
      media: gif,
      cta: ctaText,
      payload: payload,
      messageLocalization: localization,
      ctaLocalization: localization
    ))

    XCTAssertEqual(content.contextTokenID, contextToken)
    XCTAssertEqual(validMessage, content.message)
    XCTAssertEqual(gif, content.media as? FacebookGIF)
    XCTAssertEqual(ctaText, content.ctaText)
    XCTAssertEqual(payload, content.payload)
    XCTAssertEqual(localization, content.messageLocalization)
    XCTAssertEqual(localization, content.ctaLocalization)
  }

  func testCustomUpdateContentImageInitWithOnlyRequiredValues() throws {
    let content = try XCTUnwrap(CustomUpdateContentImage(
      contextTokenID: contextToken,
      message: validMessage,
      image: validImage
    ))

    XCTAssertEqual(content.contextTokenID, contextToken)
    XCTAssertEqual(validMessage, content.message)
    XCTAssertEqual(validImage, content.image)
  }

  func testCustomUpdateContentImageInitWithAllValues() throws {
    let content = try XCTUnwrap(CustomUpdateContentImage(
      contextTokenID: contextToken,
      message: validMessage,
      image: validImage,
      cta: ctaText,
      payload: payload,
      messageLocalization: localization,
      ctaLocalization: localization
    ))

    XCTAssertEqual(content.contextTokenID, contextToken)
    XCTAssertEqual(validMessage, content.message)
    XCTAssertEqual(validImage, content.image)
    XCTAssertEqual(ctaText, content.ctaText)
    XCTAssertEqual(payload, content.payload)
    XCTAssertEqual(localization, content.messageLocalization)
    XCTAssertEqual(localization, content.ctaLocalization)
  }
}
