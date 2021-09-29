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
  let validContextTokenID = "12345"

  override func setUp() {
    super.setUp()
    GamingContext.current = nil
  }

  override func tearDown() {
    GamingContext.current = nil
    super.tearDown()
  }

  func testImageContentInitWithValidValues() throws {
    GamingContext.current = GamingContext.createContext(withIdentifier: validContextTokenID, size: 0)
    var remoteContent: CustomUpdateGraphAPIContentRemote?

    do {
      remoteContent = try CustomUpdateGraphAPIContentRemote(
        customUpdateContentImage: CustomUpdateContentObjects.imageContentValid
      )
    } catch {
      XCTFail("Was not expecting an error thrown but got: \(error)")
    }
    let validContent = try XCTUnwrap(remoteContent)
    let image = try XCTUnwrap(validContent.image, "Should successfully create image content")

    XCTAssertEqual(validContent.text.defaultString, CustomUpdateContentObjects.validMessage)
    XCTAssertEqual(image, CustomUpdateContentObjects.validImage.pngData())
    XCTAssertEqual(
      validContent.contextTokenID,
      GamingContext.current?.identifier,
      "The context token identifier should be the same identifer as the current gaming context token id"
    )
  }

  func testImageContentInitWithInvalidMessage() throws {
    GamingContext.current = GamingContext.createContext(withIdentifier: validContextTokenID, size: 0)
    var remoteContent: CustomUpdateGraphAPIContentRemote?

    do {
      remoteContent = try CustomUpdateGraphAPIContentRemote(
        customUpdateContentImage: CustomUpdateContentObjects.imageContentInvalidMessage
      )
    } catch CustomUpdateContentError.invalidMessage {
    } catch {
      return XCTFail("Should not throw an error other than invalid message: \(error)")
    }

    XCTAssertNil(remoteContent, "A remote content object should not be created with an invalid message")
  }

  func testImageContentInitWithInvalidImage() throws {
    GamingContext.current = GamingContext.createContext(withIdentifier: validContextTokenID, size: 0)
    var remoteContent: CustomUpdateGraphAPIContentRemote?

    do {
      remoteContent = try CustomUpdateGraphAPIContentRemote(
        customUpdateContentImage: CustomUpdateContentObjects.imageContentInvalidImage
      )
    } catch CustomUpdateContentError.invalidImage {
    } catch {
      return XCTFail("Should not throw an error other than invalid image: \(error)")
    }

    XCTAssertNil(remoteContent, "A remote content object should not be created with an invalid image ")
  }

  func testImageContentInitWhenNotInGamingContext() throws {
    var remoteContent: CustomUpdateGraphAPIContentRemote?

    do {
      remoteContent = try CustomUpdateGraphAPIContentRemote(
        customUpdateContentImage: CustomUpdateContentObjects.imageContentValid
      )
    } catch CustomUpdateContentError.notInGameContext {
    } catch {
      return XCTFail("Should not throw an error other than not in game context: \(error)")
    }

    XCTAssertNil(remoteContent, "A remote content object should not be created if the current game context is empty")
  }

  func testMediaContentInitWithValidValues() throws {
    GamingContext.current = GamingContext.createContext(withIdentifier: validContextTokenID, size: 0)
    var remoteContent: CustomUpdateGraphAPIContentRemote?

    do {
      remoteContent = try CustomUpdateGraphAPIContentRemote(
        customUpdateContentMedia: CustomUpdateContentObjects.mediaContentValid)
    } catch {
      XCTFail("Was not expecting an error thrown but got: \(error)")
    }
    let media = try XCTUnwrap(remoteContent?.media)

    XCTAssertEqual(remoteContent?.contextTokenID, GamingContext.current?.identifier)
    XCTAssertEqual(remoteContent?.text.defaultString, CustomUpdateContentObjects.validMessage)
    XCTAssertEqual(media.gif, CustomUpdateContentObjects.gifMedia)
  }

  func testMediaContentInitWithInvalidMessage() throws {
    GamingContext.current = GamingContext.createContext(withIdentifier: validContextTokenID, size: 0)
    var remoteContent: CustomUpdateGraphAPIContentRemote?

    do {
      remoteContent = try CustomUpdateGraphAPIContentRemote(
        customUpdateContentMedia: CustomUpdateContentObjects.mediaContentInvalidMessage
      )
    } catch CustomUpdateContentError.invalidMessage {
    } catch {
      return XCTFail("Should not throw an error other than invalid message: \(error)")
    }

    XCTAssertNil(remoteContent, "A remote content object should not be created with an invalid message")
  }

  func testMediaContentInitWhenNotInGamingContext() throws {
    var remoteContent: CustomUpdateGraphAPIContentRemote?
    var didThrowNotInGamingContextError = false

    do {
      remoteContent = try CustomUpdateGraphAPIContentRemote(
        customUpdateContentMedia: CustomUpdateContentObjects.mediaContentValid
      )
    } catch CustomUpdateContentError.notInGameContext {
      didThrowNotInGamingContextError = true
    } catch {
      return XCTFail("Should not throw an error other than not in game context: \(error)")
    }

    XCTAssertNil(remoteContent, "A remote content object should if no gaming context is present")
    XCTAssertTrue(
      didThrowNotInGamingContextError,
      "Should throw a not in gaming context error when the user is not currently in gaming context"
    )
  }
}
