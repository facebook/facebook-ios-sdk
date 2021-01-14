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

import FBSDKCoreKit
import XCTest

class ProfilePictureView: XCTestCase {
  var sampleProfile: Profile {
    return Profile(
      userID: "Sample ID",
      firstName: nil,
      middleName: nil,
      lastName: nil,
      name: "Sample Name",
      linkURL: nil,
      refreshDate: nil,
      imageURL: URL(string:"https://www.facebook.com/"),
      email:nil
    )
  }
  var sampleProfileWithoutImageURL: Profile {
    return Profile(
      userID: "Sample ID",
      firstName: nil,
      middleName: nil,
      lastName: nil,
      name: "Sample Name",
      linkURL: nil,
      refreshDate: nil
    )
  }

  override func setUp() {
    super.setUp()

    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    Profile.setCurrent(nil, shouldPostNotification: false)
  }

  // MARK: - Update Image

  func testImageUpdateWithoutAccessTokenWithProfile() {
    let view = TestView()
    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    Profile.setCurrent(sampleProfile, shouldPostNotification: false)

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
    let view = TestView()
    AccessToken.setCurrent(SampleAccessToken.validToken, shouldDispatchNotif: false)
    Profile.setCurrent(sampleProfile, shouldPostNotification: false)

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
    let view = TestView()
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
    let view = TestView()
    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    Profile.setCurrent(sampleProfileWithoutImageURL, shouldPostNotification: false)

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

  func testReceivingAccessTokenNotificationWithDidChangeUserIdKey() {
    let view = TestView()
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
    let view = TestView()
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
    let view = TestView()
    Profile.setCurrent(sampleProfile, shouldPostNotification: false)
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
    let view = TestView()
    Profile.setCurrent(sampleProfile, shouldPostNotification: false)

    view._updateImageWithProfile()

    XCTAssertEqual(
      view.fetchAndSetImageCount,
      1,
      "Should try to fetch image for a profile that have an imageURL"
    )
    XCTAssertNotNil(view.lastState(), "Should update state when profile has an imageURL");
  }

  func testUpdatinImageWithProfileWithoutImageURL() {
    let view = TestView()
    Profile.setCurrent(sampleProfileWithoutImageURL, shouldPostNotification: false)

    view._updateImageWithProfile()

    XCTAssertEqual(
      view.fetchAndSetImageCount,
      0,
      "Should try to fetch image for a profile that does not have an imageURL"
    )
    XCTAssertNil(view.lastState(), "Should not update state when profile does not have an imageURL")
  }

  func testUpdatingImageWithValidAccessToken() {
    let view = TestView()
    AccessToken.setCurrent(SampleAccessToken.validToken, shouldDispatchNotif: false)

    view._updateImageWithAccessToken()

    XCTAssertEqual(
      view.fetchAndSetImageCount,
      1,
      "Should try to fetch image for a valid access token"
    )
    XCTAssertNotNil(view.lastState(), "Should update state when access token is valid");
  }

  func testUpdatingImageWithInvalidAccessToken() {
    let view = TestView()
    AccessToken.setCurrent(SampleAccessToken.expiredToken, shouldDispatchNotif: false)

    view._updateImageWithAccessToken()

    XCTAssertEqual(
      view.fetchAndSetImageCount,
      0,
      "Should not try to fetch image for an invalid access token"
    )
    XCTAssertNil(view.lastState(), "Should not update state when access token is not valid")
  }
}

class TestView: FBProfilePictureView {
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

  override func _fetchAndSetImage(with url:URL?, state:FBProfilePictureViewState) {
    fetchAndSetImageCount += 1
  }
}
