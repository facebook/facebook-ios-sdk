/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import XCTest

final class ProfilePictureViewTests: XCTestCase {

  override func setUp() {
    super.setUp()

    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    Profile.setCurrent(nil, shouldPostNotification: false)
  }

  // MARK: - Update Image

  func testImageUpdateWithoutAccessTokenWithProfile() {
    let view = TestProfilePictureView()
    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    Profile.setCurrent(SampleUserProfiles.createValid(), shouldPostNotification: false)

    view._updateImage()

    XCTAssertEqual(
      view.updateImageWithProfileCount,
      1,
      "Should use the profile when there is no access token"
    )
    XCTAssertEqual(
      view.updateImageWithAccessTokenCount,
      0,
      "Should not use the access token when there is no access token"
    )
  }

  func testImageUpdateWithAccessTokenWithProfile() {
    let view = TestProfilePictureView()
    AccessToken.setCurrent(SampleAccessTokens.validToken, shouldDispatchNotif: false)
    Profile.setCurrent(SampleUserProfiles.createValid(), shouldPostNotification: false)

    view._updateImage()

    XCTAssertEqual(
      view.updateImageWithProfileCount,
      0,
      "Should not use the profile when there is an access token"
    )
    XCTAssertEqual(
      view.updateImageWithAccessTokenCount,
      1,
      "Should use the access token when there is one available"
    )
  }

  func testImageUpdateWithoutAccessTokenWithoutProfile() {
    let view = TestProfilePictureView()
    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    Profile.setCurrent(nil, shouldPostNotification: false)

    view._updateImage()

    XCTAssertEqual(
      view.updateImageWithProfileCount,
      0,
      "Should not use the profile when there is no access token or current profile"
    )
    XCTAssertEqual(
      view.updateImageWithAccessTokenCount,
      0,
      "Should not use the access token when there is no access token or current profile"
    )
  }

  func testImageUpdateWithoutAccessTokenWithProfileNoImageURL() {
    let view = TestProfilePictureView()
    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    Profile.setCurrent(SampleUserProfiles.missingImageURL, shouldPostNotification: false)

    view._updateImage()

    XCTAssertEqual(
      view.updateImageWithProfileCount,
      0,
      "Should not use the profile when there is no image url available"
    )
    XCTAssertEqual(
      view.updateImageWithAccessTokenCount,
      0,
      "Should not use the access token when there is no access token"
    )
  }

  // MARK: - Token Notifications

  func testReceivingAccessTokenNotificationWithDidChangeUserIDKey() {
    let view = TestProfilePictureView()
    let notification = Notification(
      name: .AccessTokenDidChange,
      object: nil,
      userInfo: [AccessTokenDidChangeUserIDKey: "foo"]
    )

    view._accessTokenDidChange(notification)

    XCTAssertEqual(
      view.updateImageWithAccessTokenCount,
      1,
      "An access token notification with a changed user id key should trigger an image update"
    )
  }

  func testReceivingAccessTokenNotificationWithoutRelevantUserInfo() {
    let view = TestProfilePictureView()
    let notification = Notification(
      name: .AccessTokenDidChange,
      object: nil,
      userInfo: nil
    )

    view._accessTokenDidChange(notification)

    XCTAssertEqual(
      view.updateImageWithAccessTokenCount,
      0,
      "An access token notification without relevant user info should not trigger an image update"
    )
  }

  func testReceivingProfileNotification() {
    let view = TestProfilePictureView()
    Profile.setCurrent(SampleUserProfiles.createValid(), shouldPostNotification: false)
    let notification = Notification(
      name: .ProfileDidChange,
      object: nil,
      userInfo: nil
    )

    view._profileDidChange(notification)

    XCTAssertEqual(
      view.updateImageWithProfileCount,
      1,
      "An profile change should trigger an image update"
    )
  }

  // MARK: - Updating Content

  func testUpdatinImageWithProfileWithImageURL() {
    let view = TestProfilePictureView()
    Profile.setCurrent(SampleUserProfiles.createValid(), shouldPostNotification: false)

    view._updateImageWithProfile()

    XCTAssertEqual(
      view.fetchAndSetImageCount,
      1,
      "Should try to fetch image for a profile that have an imageURL"
    )
    XCTAssertNotNil(view.lastState(), "Should update state when profile has an imageURL")
  }

  func testUpdatinImageWithProfileWithoutImageURL() {
    let view = TestProfilePictureView()
    Profile.setCurrent(SampleUserProfiles.missingImageURL, shouldPostNotification: false)

    view._updateImageWithProfile()

    XCTAssertEqual(
      view.fetchAndSetImageCount,
      0,
      "Should try to fetch image for a profile that does not have an imageURL"
    )
    XCTAssertNil(view.lastState(), "Should not update state when profile does not have an imageURL")
  }

  func testUpdatingImageWithValidAccessToken() {
    let view = TestProfilePictureView()
    AccessToken.setCurrent(SampleAccessTokens.validToken, shouldDispatchNotif: false)

    view._updateImageWithAccessToken()

    XCTAssertEqual(
      view.fetchAndSetImageCount,
      1,
      "Should try to fetch image for a valid access token"
    )
    XCTAssertNotNil(view.lastState(), "Should update state when access token is valid")
  }

  func testUpdatingImageWithInvalidAccessToken() {
    let view = TestProfilePictureView()
    AccessToken.setCurrent(SampleAccessTokens.expiredToken, shouldDispatchNotif: false)

    view._updateImageWithAccessToken()

    XCTAssertEqual(
      view.fetchAndSetImageCount,
      0,
      "Should not try to fetch image for an invalid access token"
    )
    XCTAssertNil(view.lastState(), "Should not update state when access token is not valid")
  }
}

private final class TestProfilePictureView: FBProfilePictureView {
  var updateImageWithAccessTokenCount = 0
  var updateImageWithProfileCount = 0
  var fetchAndSetImageCount = 0

  override func _updateImageWithAccessToken() {
    updateImageWithAccessTokenCount += 1

    super._updateImageWithAccessToken()
  }

  override func _updateImageWithProfile() {
    updateImageWithProfileCount += 1

    super._updateImageWithProfile()
  }

  override func _fetchAndSetImage(with url: URL?, state: FBProfilePictureViewState) {
    fetchAndSetImageCount += 1
  }
}
