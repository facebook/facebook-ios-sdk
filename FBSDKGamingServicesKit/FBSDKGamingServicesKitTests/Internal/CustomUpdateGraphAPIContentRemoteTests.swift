/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

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
    GamingContext.current = GamingContext(identifier: validContextTokenID, size: 0)
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
    GamingContext.current = GamingContext(identifier: validContextTokenID, size: 0)
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
    GamingContext.current = GamingContext(identifier: validContextTokenID, size: 0)
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
    GamingContext.current = GamingContext(identifier: validContextTokenID, size: 0)
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
    GamingContext.current = GamingContext(identifier: validContextTokenID, size: 0)
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
