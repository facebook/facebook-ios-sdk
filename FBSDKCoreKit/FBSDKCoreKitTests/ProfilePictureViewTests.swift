/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class ProfilePictureViewTests: XCTestCase {
  // swiftlint:disable implicitly_unwrapped_optional
  var profilePictureView: FBProfilePictureView!
  var testProfile: Profile! = SampleUserProfiles.createValid()
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    Profile.setCurrent(nil, shouldPostNotification: false)
    testProfile = SampleUserProfiles.createValid()
    profilePictureView = FBProfilePictureView(frame: .zero)
  }

  override func tearDown() {
    profilePictureView = nil
    testProfile = nil

    super.tearDown()
  }

  // MARK: - Initialization

  func testInitializationWithoutProfileWithFrame() {
    let profilePictureFrame = CGRect(x: 0, y: 0, width: 100, height: 100)
    profilePictureView = FBProfilePictureView(frame: profilePictureFrame)

    XCTAssertEqual(
      profilePictureView.backgroundColor,
      .white,
      .setsBackgroundColor
    )
    XCTAssertEqual(
      profilePictureView.contentMode,
      .scaleAspectFit,
      .setsContentMode
    )
    XCTAssertEqual(
      profilePictureView.frame,
      profilePictureFrame,
      .setsCustomFrame
    )
    XCTAssertEqual(
      profilePictureView.profileID,
      "me",
      .setsProfileID
    )
    XCTAssertTrue(profilePictureView.subviews.first is UIImageView, .addsImageView)
    XCTAssertFalse(profilePictureView.isUserInteractionEnabled, .disablesUserInteraction)
  }

  func testInitializationWithProfileWithoutFrame() {
    profilePictureView = FBProfilePictureView(profile: testProfile)
    initialConfigurationSetupWithProfile()
    XCTAssertEqual(
      profilePictureView.frame,
      .zero,
      .setsDefaultFrame
    )
    XCTAssertEqual(
      profilePictureView.profileID,
      "123",
      .setsCustomProfile
    )
  }

  func testInitializationWithProfileWithFrame() {
    let profilePictureFrame = CGRect(x: 0, y: 0, width: 100, height: 100)
    profilePictureView = FBProfilePictureView(frame: profilePictureFrame, profile: testProfile)
    initialConfigurationSetupWithProfile()
    XCTAssertEqual(
      profilePictureView.frame,
      profilePictureFrame,
      .setsCustomFrame
    )
    XCTAssertEqual(
      profilePictureView.profileID,
      "123",
      .setsCustomProfile
    )
  }

  // MARK: - Image Update

  func testPlaceholderImage() throws {
    let profilePictureFrame = CGRect(x: 0, y: 0, width: 100, height: 100)
    profilePictureView = FBProfilePictureView(frame: profilePictureFrame)
    profilePictureView._setPlaceholderImage()

    let expecation = expectation(description: "placeholder image expectation")
    expecation.isInverted = true
    waitForExpectations(timeout: 2)

    XCTAssertNotNil(profilePictureView.imageView.image, .setsPlaceholderImage)
  }

  func testUpdateImageWithDataAndSameState() throws {
    let state = FBSDKProfilePictureViewState(
      profileID: "123",
      size: .zero,
      scale: 0,
      pictureMode: .normal,
      imageShouldFit: false
    )
    profilePictureView.lastState = state
    profilePictureView.imageView.image = nil

    let updateImagePredicate = NSPredicate { _, _ in
      self.profilePictureView.imageView.image != nil
    }

    _ = expectation(for: updateImagePredicate, evaluatedWith: nil)
    DispatchQueue.global(qos: .userInitiated).async {
      self.profilePictureView._updateImage(with: Data.redIconImage, state: state)
    }

    waitForExpectations(timeout: 2)
    XCTAssertNotNil(profilePictureView.imageView.image, .updatesImageIfSameState)
  }

  func testUpdateImageWithDataAndDifferentState() throws {
    profilePictureView = FBProfilePictureView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

    let oldState = FBSDKProfilePictureViewState(
      profileID: "123",
      size: .zero,
      scale: 0,
      pictureMode: .normal,
      imageShouldFit: false
    )
    profilePictureView.lastState = oldState

    let newState = FBSDKProfilePictureViewState(
      profileID: "test12345",
      size: .zero,
      scale: 0,
      pictureMode: .normal,
      imageShouldFit: true
    )
    profilePictureView._updateImage(with: Data.redIconImage, state: newState)

    XCTAssertNil(
      profilePictureView.imageView.image,
      .doesNotUpdateImageIfDifferentState
    )
  }

  func testAccessTokenDidChangeNotificationWithUserInfoKey() {
    let notification = Notification(
      name: .AccessTokenDidChange,
      object: nil,
      userInfo: [AccessTokenDidChangeUserIDKey: true]
    )
    Profile.setCurrent(testProfile, shouldPostNotification: false)
    profilePictureView._updateImageWithProfile()
    XCTAssertNotNil(profilePictureView.lastState, .hasLastState)
    profilePictureView._accessTokenDidChange(notification)
    XCTAssertNil(profilePictureView.lastState, .hasResetLastStateOnAccessTokenChange)
  }

  // MARK: - Helpers

  func initialConfigurationSetupWithProfile() {
    XCTAssertNotEqual(
      profilePictureView.backgroundColor,
      .white,
      .setsBackgroundColor
    )
    XCTAssertNotEqual(
      profilePictureView.contentMode,
      .scaleAspectFit,
      .setsContentMode
    )
    XCTAssertTrue(
      profilePictureView.subviews.isEmpty,
      .doesNotAddImageView
    )
    XCTAssertTrue(profilePictureView.isUserInteractionEnabled, .enablesUserInteraction)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let setsCustomProfile = "We are able to set a custom profile during initialization"
  static let hasProfileImage = "A profile picture view has a profile image"
  static let setsBackgroundColor = "Profile picture view background color is set to a color during initialization"
  static let setsContentMode = "Profile picture view content mode is set to aspect fit during initialization"
  static let setsCustomFrame = "Profile picture view can be passed a custom frame during initialization"
  static let setsProfileID = "Profile picture view sets a default profile ID during initialization"
  static let addsImageView = "Profile picture view adds an image view to its view hierarchy during initialization"
  static let disablesUserInteraction = """
      Profile picture view user interaction is disabled when initiating without a profile
    """
  static let setsDefaultFrame = """
      If no custom frame is passed during initialization default profile picture view frame should be zero
    """
  static let setsPlaceholderImage = "Profile picture view can set a place holder image when a there is no user image"
  static let hasLastState = "Profile picture view has a last state available"
  static let updatesImageIfSameState = "Profile picture view image is updated when state has not changed"
  static let doesNotUpdateImageIfDifferentState = """
      Profile picture view image image should not be updated when having different state than the last one
    """
  static let hasResetLastStateOnAccessTokenChange = """
       State should reset when we receive an access token notification, we have a profile id equals "me", \
       and we have a user id value.
    """
  static let doesNotAddImageView = """
       No image view is added to the profile picture view hierarchy when initiating with a profile
    """
  static let enablesUserInteraction = """
       Profile picture view user interaction is enabled when initiating with a profile
    """
}

// MARK: - Test Values

fileprivate extension UIImage {
  static let redIcon = UIImage(
    named: "redSilhouette.png",
    in: Bundle(for: ProfilePictureViewTests.self),
    compatibleWith: nil
  )
}

fileprivate extension Data {
  static let redIconImage = UIImage.redIcon!.pngData()! // swiftlint:disable:this force_unwrapping
}
