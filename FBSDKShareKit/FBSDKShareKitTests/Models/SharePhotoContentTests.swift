/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

final class SharePhotoContentTests: XCTestCase {

  func testProperties() {
    let content = ShareModelTestUtility.photoContent

    XCTAssertEqual(content.contentURL, ShareModelTestUtility.contentURL)
    XCTAssertEqual(content.peopleIDs, ShareModelTestUtility.peopleIDs)
    XCTAssertEqual(content.placeID, ShareModelTestUtility.placeID)
    XCTAssertEqual(content.ref, ShareModelTestUtility.ref)

    XCTAssertEqual(content.photos.count, ShareModelTestUtility.photos.count)
    zip(content.photos, ShareModelTestUtility.photos).forEach { photo1, photo2 in
      XCTAssertEqual(photo1.imageURL, photo2.imageURL)
      XCTAssertEqual(photo1.isUserGenerated, photo2.isUserGenerated)
    }
  }

  func testCoding() throws {
    let content = ShareModelTestUtility.photoContent
    let data = NSKeyedArchiver.archivedData(withRootObject: content)
    let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
    unarchiver.requiresSecureCoding = true
    let unarchivedObject = try XCTUnwrap(
      unarchiver.decodeObject(of: SharePhotoContent.self, forKey: NSKeyedArchiveRootObjectKey)
    )

    XCTAssertEqual(unarchivedObject.contentURL, content.contentURL)
    XCTAssertEqual(unarchivedObject.hashtag, content.hashtag)
    XCTAssertEqual(unarchivedObject.peopleIDs, content.peopleIDs)
    XCTAssertEqual(unarchivedObject.placeID, content.placeID)
    XCTAssertEqual(unarchivedObject.ref, content.ref)
    XCTAssertEqual(unarchivedObject.pageID, content.pageID)

    XCTAssertEqual(content.photos.count, ShareModelTestUtility.photos.count)
    zip(content.photos, ShareModelTestUtility.photos).forEach { photo1, photo2 in
      XCTAssertEqual(photo1.imageURL, photo2.imageURL)
      XCTAssertEqual(photo1.isUserGenerated, photo2.isUserGenerated)
    }
  }

  func testValidationWithValidContent() {
    let content = SharePhotoContent()
    content.contentURL = ShareModelTestUtility.contentURL
    content.peopleIDs = ShareModelTestUtility.peopleIDs
    content.photos = [ShareModelTestUtility.photoWithImage]
    content.placeID = ShareModelTestUtility.placeID
    content.ref = ShareModelTestUtility.ref

    XCTAssertNoThrow(try _ShareUtility.validateShare(content, bridgeOptions: []))
  }

  func testValidationWithNilPhotos() {
    let content = SharePhotoContent()

    XCTAssertThrowsError(
      try _ShareUtility.validateShare(content, bridgeOptions: []),
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
      try _ShareUtility.validateShare(content, bridgeOptions: []),
      "Should throw an error"
    ) { error in
      let nsError = error as NSError
      XCTAssertEqual(nsError.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(nsError.userInfo[ErrorArgumentNameKey] as? String, "photos")
    }
  }
}
