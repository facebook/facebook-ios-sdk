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
class CustomUpdateGraphAPIContentRemoteTests: XCTestCase {

  func testImageContentInitWithValidValues() throws {
    let remoteContent = try XCTUnwrap(CustomUpdateGraphAPIContentRemote(
      customUpdateContentImage: CustomUpdateContentObjects.imageContentValid())
    )
    let image = try XCTUnwrap(remoteContent.image)

    XCTAssertEqual(remoteContent.contextTokenID, CustomUpdateContentObjects.validID)
    XCTAssertEqual(remoteContent.text.defaultString, CustomUpdateContentObjects.validMessage)
    XCTAssertEqual(image, CustomUpdateContentObjects.validImage.pngData())
  }

  func testImageContentInitWithInvalidContextID() {
    let remoteContent = CustomUpdateGraphAPIContentRemote(
      customUpdateContentImage: CustomUpdateContentObjects.imageContentInvalidContextID())

    XCTAssertNil(remoteContent)
  }

  func testImageContentInitWithInvalidMessage() {
    let remoteContent = CustomUpdateGraphAPIContentRemote(
      customUpdateContentImage: CustomUpdateContentObjects.imageContentInvalidMessage()
    )

    XCTAssertNil(remoteContent)
  }

  func testImageContentInitWithInvalidImage() {
    let remoteContent = CustomUpdateGraphAPIContentRemote(
      customUpdateContentImage: CustomUpdateContentObjects.imageContentInvalidImage())

    XCTAssertNil(remoteContent)
  }

  func testMediaContentInitWithValidValues() throws {
    let remoteContent = try XCTUnwrap(CustomUpdateGraphAPIContentRemote(
      customUpdateContentMedia: CustomUpdateContentObjects.mediaContentValid()))
    let media = try XCTUnwrap(remoteContent.media)

    XCTAssertEqual(remoteContent.contextTokenID, CustomUpdateContentObjects.validID)
    XCTAssertEqual(remoteContent.text.defaultString, CustomUpdateContentObjects.validMessage)
    XCTAssertEqual(media.gif, CustomUpdateContentObjects.gifMedia)
  }

  func testMediaContentInitWithInvalidContextID() {
    let remoteContent = CustomUpdateGraphAPIContentRemote(
      customUpdateContentMedia: CustomUpdateContentObjects.mediaContentInvalidContextID())

    XCTAssertNil(remoteContent)
  }

  func testMediaInitWithInvalidMessage() {
    let remoteContent = CustomUpdateGraphAPIContentRemote(
      customUpdateContentMedia: CustomUpdateContentObjects.mediaContentInvalidMessage())

    XCTAssertNil(remoteContent)
  }
}
