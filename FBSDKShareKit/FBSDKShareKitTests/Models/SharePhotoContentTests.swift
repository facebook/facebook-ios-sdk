/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

class SharePhotoContentTests: XCTestCase {

  func testProperties() {
    let content = ShareModelTestUtility.photoContent

    XCTAssertEqual(content.contentURL, ShareModelTestUtility.contentURL)
    XCTAssertEqual(content.peopleIDs, ShareModelTestUtility.peopleIDs)
    XCTAssertEqual(content.photos, ShareModelTestUtility.photos)
    XCTAssertEqual(content.placeID, ShareModelTestUtility.placeID)
    XCTAssertEqual(content.ref, ShareModelTestUtility.ref)
  }

  func testCopy() throws {
    let content = ShareModelTestUtility.photoContent
    let contentCopy = try XCTUnwrap(
      content.copy() as? SharePhotoContent,
      "Unable to make a copy or casting to 'SharePhotoContent' failed"
    )
    XCTAssertEqual(content, contentCopy)
    XCTAssertNotIdentical(content, contentCopy)
  }

  func testCoding() {
    let content = ShareModelTestUtility.photoContent
    let data = NSKeyedArchiver.archivedData(withRootObject: content)
    let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
    unarchiver.requiresSecureCoding = true
    let unarchivedObject = unarchiver.decodeObject(
      of: SharePhotoContent.self,
      forKey: NSKeyedArchiveRootObjectKey
    )
    XCTAssertEqual(unarchivedObject, content)
  }

  func testValidationWithValidContent() {
    let content = SharePhotoContent()
    content.contentURL = ShareModelTestUtility.contentURL
    content.peopleIDs = ShareModelTestUtility.peopleIDs
    content.photos = [ShareModelTestUtility.photoWithImage]
    content.placeID = ShareModelTestUtility.placeID
    content.ref = ShareModelTestUtility.ref

    XCTAssertNoThrow(try ShareUtility.validateShare(content, bridgeOptions: []))
  }

  func testValidationWithNilPhotos() {
    let content = SharePhotoContent()

    XCTAssertThrowsError(
      try ShareUtility.validateShare(content, bridgeOptions: []),
      "Should throw an error"
    ) { error in
      let nsError = error as NSError
      XCTAssertEqual(nsError.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(nsError.userInfo[ErrorArgumentNameKey] as? String, "photos")
    }
  }

  func testValidationWithEmptyPhotos() {
    let content = SharePhotoContent()
    content.photos = []

    XCTAssertThrowsError(
      try ShareUtility.validateShare(content, bridgeOptions: []),
      "Should throw an error"
    ) { error in
      let nsError = error as NSError
      XCTAssertEqual(nsError.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(nsError.userInfo[ErrorArgumentNameKey] as? String, "photos")
    }
  }
}
