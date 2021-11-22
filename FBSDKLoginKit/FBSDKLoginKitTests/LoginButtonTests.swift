/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if BUCK
import FacebookCore
#endif

import FBSDKLoginKit
import TestTools
import XCTest

// swiftlint:disable type_body_length

class LoginButtonTests: XCTestCase {

  let validNonce: String = "abc123"
  let loginProvider = TestLoginProvider()
  lazy var factory = TestGraphRequestFactory()
  lazy var button = FBLoginButton()
  var sampleToken: AuthenticationToken {
    AuthenticationToken(tokenString: "abc", nonce: "123")
  }
  private let delegate = TestLoginButtonDelegate()

  override func setUp() {
    super.setUp()

    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    AuthenticationToken.current = nil
    Profile.current = nil

    button.delegate = delegate
    button.setLoginProvider(loginProvider)
    button.graphRequestFactory = factory
  }

  // MARK: Nonce
  func testDefaultNonce() {
    XCTAssertNil(FBLoginButton().nonce, "Should not have a default nonce")
  }

  func testSettingInvalidNonce() {
    button.nonce = "   "

    XCTAssertNil(
      button.nonce,
      "Should not set an invalid nonce"
    )
  }

  func testSettingValidNonce() {
    button.nonce = validNonce

    XCTAssertEqual(
      button.nonce,
      validNonce,
      "Should set a valid nonce"
    )
  }

  func testLoginConfigurationWithoutNonce() {
    XCTAssertNotNil(
      button.loginConfiguration(),
      "Should be able to create a login configuration without a provided nonce"
    )
  }

  func testLoginConfigurationWithInvalidNonce() {
    button.nonce = "   "

    XCTAssertNotNil(
      button.loginConfiguration(),
      "Should not create a login configuration with an invalid nonce"
    )
  }

  func testLoginConfigurationWithValidNonce() {
    button.nonce = validNonce

    XCTAssertEqual(
      button.loginConfiguration().nonce,
      validNonce,
      "Should create a login configuration with valid nonce"
    )
  }

  // MARK: - Initial Content Update

  func testInitialContentUpdateWithInactiveAccessTokenWithProfile() {
    let button = TestButton()
    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    Profile.setCurrent(SampleUserProfiles.createValid(), shouldPostNotification: false)

    button._initializeContent()

    XCTAssertEqual(
      button.updateContentForProfileCallCount,
      1,
      "Should use the profile when there is no access token"
    )
    XCTAssertEqual(
      button.updateContentForAccessTokenCallCount,
      0,
      "Should not use the access token when there is no access token"
    )
  }

  func testInitialContentUpdateWithActiveAccessTokenWithProfile() {
    let button = TestButton()
    AccessToken.setCurrent(SampleAccessTokens.validToken, shouldDispatchNotif: false)
    let profile = Profile(
      userID: "Sample ID",
      firstName: nil,
      middleName: nil,
      lastName: nil,
      name: "Sample Name",
      linkURL: nil,
      refreshDate: nil
    )
    Profile.setCurrent(profile, shouldPostNotification: false)

    button._initializeContent()

    XCTAssertEqual(
      button.updateContentForProfileCallCount,
      0,
      "Should not use the profile when there is an access token"
    )
    XCTAssertEqual(
      button.updateContentForAccessTokenCallCount,
      1,
      "Should use the access token when there is one available"
    )
  }

  func testInitialContentUpdateWithoutAccessTokenWithoutProfile() {
    let button = TestButton()
    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    Profile.setCurrent(nil, shouldPostNotification: false)

    button._initializeContent()

    XCTAssertEqual(
      button.updateContentForProfileCallCount,
      0,
      "Should not use the profile when there is no access token or current profile"
    )
    XCTAssertEqual(
      button.updateContentForAccessTokenCallCount,
      0,
      "Should not use the access token when there is no access token or current profile"
    )
    XCTAssertFalse(
      button.isSelected,
      "Should not be selected when there is no access token or current profile"
    )
  }

  // MARK: - Determining Authentication Status

  func testDeterminingAuthenticationWithAccessTokenWithoutAuthToken() {
    AccessToken.setCurrent(SampleAccessTokens.validToken, shouldDispatchNotif: false)

    XCTAssertTrue(
      button._isAuthenticated(),
      "Should consider a user authenticated if they have a current access token"
    )
  }

  func testDeterminingAuthenticationWithoutAccessTokenWithAuthToken() {
    AuthenticationToken.current = sampleToken

    XCTAssertTrue(
      button._isAuthenticated(),
      "Should consider a user authenticated if they have a current authentication token"
    )
  }

  // MARK: - Handling Notifications

  func testReceivingAccessTokenNotificationWithDidChangeUserIdKey() {
    let button = TestButton()
    let notification = Notification(
      name: .AccessTokenDidChange,
      object: nil,
      userInfo: [AccessTokenDidChangeUserIDKey: "foo"]
    )

    button._accessTokenDidChange(notification)

    XCTAssertEqual(
      button.updateContentForAccessTokenCallCount,
      1,
      "An access token notification with a changed user id key should trigger a content update"
    )
  }

  func testReceivingAccessTokenNotificationWithTokenDidExpireKey() {
    let button = TestButton()
    let notification = Notification(
      name: .AccessTokenDidChange,
      object: nil,
      userInfo: [AccessTokenDidExpireKey: "foo"]
    )

    button._accessTokenDidChange(notification)

    XCTAssertEqual(
      button.updateContentForAccessTokenCallCount,
      1,
      "An access token notification with an expired token key should trigger a content update"
    )
  }

  func testReceivingAccessTokenNotificationWithoutRelevantUserInfo() {
    let button = TestButton()
    let notification = Notification(
      name: .AccessTokenDidChange,
      object: nil,
      userInfo: nil
    )

    button._accessTokenDidChange(notification)

    XCTAssertEqual(
      button.updateContentForAccessTokenCallCount,
      0,
      "An access token notification without relevant user info should not trigger a content update"
    )
  }

  func testReceivingProfileNotification() {
    let button = TestButton()
    let notification = Notification(
      name: .ProfileDidChange,
      object: nil,
      userInfo: nil
    )

    button._profileDidChange(notification)

    XCTAssertEqual(
      button.updateContentForProfileCallCount,
      1,
      "An profile change should trigger a content update"
    )
  }

  // MARK: - Updating Content

  func testUpdatingContentWithMissingProfile() {
    button._updateContent(forUserProfile: nil)

    XCTAssertFalse(
      button.isSelected,
      "Should not be selected if there is not a profile"
    )
    XCTAssertNil(button.userName())
    XCTAssertNil(button.userID())
  }

  func testUpdatingContentWithProfile() {
    let profile = SampleUserProfiles.createValid()
    button._updateContent(forUserProfile: profile)

    XCTAssertTrue(
      button.isSelected,
      "Should be selected if there is a valid profile"
    )
    XCTAssertEqual(button.userName(), profile.name)
    XCTAssertEqual(button.userID(), profile.userID)
  }

  func testUpdatingContentForProfileWithNewId() {
    let button = TestButton()
    let profile = SampleUserProfiles.createValid(name: name)
    button._updateContent(forUserProfile: SampleUserProfiles.createValid())
    button._updateContent(forUserProfile: profile)

    XCTAssertEqual(
      button.userName(),
      profile.name,
      "Should update the user information with the updated profile information"
    )
    XCTAssertEqual(
      button.userID(),
      profile.userID,
      "Should update the user information with the updated profile information"
    )
  }

  func testUpdatingContentForProfileWithNewName() {
    let button = TestButton()
    let profile = SampleUserProfiles.createValid(name: name)
    button._updateContent(forUserProfile: SampleUserProfiles.createValid())
    button._updateContent(forUserProfile: profile)

    XCTAssertEqual(
      button.userName(),
      profile.name,
      "Should update the user information with the updated profile information"
    )
    XCTAssertEqual(
      button.userID(),
      profile.userID,
      "Should update the user information with the updated profile information"
    )
  }

  func testUpdatingContentWithValidAccessToken() {
    let button = TestButton()
    AccessToken.setCurrent(SampleAccessTokens.validToken, shouldDispatchNotif: false)

    button._updateContentForAccessToken()

    XCTAssertEqual(
      button.fetchAndSetContentCallCount,
      1,
      "Should try to fetch content for a valid access token"
    )
  }

  func testUpdatingContentWithInvalidAccessToken() {
    let button = TestButton()
    AccessToken.setCurrent(SampleAccessTokens.expiredToken, shouldDispatchNotif: false)

    button._updateContentForAccessToken()
    button._updateContentForAccessToken()

    XCTAssertEqual(
      button.fetchAndSetContentCallCount,
      0,
      "Should not try to fetch content for an invalid access token"
    )
  }

  func testUpdatingContentWithIdenticalAccessToken() {
    let button = TestButton()

    // Make sure the username and id properties on button are set to the same values
    // as the access token. This is an easy way to do with without having to stub
    // a network call
    let profile = SampleUserProfiles.createValid(userID: SampleAccessTokens.validToken.userID)
    button._updateContent(forUserProfile: profile)

    AccessToken.setCurrent(SampleAccessTokens.validToken, shouldDispatchNotif: false)

    button._updateContentForAccessToken()

    XCTAssertEqual(
      button.fetchAndSetContentCallCount,
      0,
      "Should not try to fetch content for a token if the user identifier has not changed"
    )
  }

  // MARK: - Fetching Content

  func testFetchContentGraphRequestCreation() throws {
    button._fetchAndSetContent()

    let request = try XCTUnwrap(factory.capturedRequests.first)
    XCTAssertEqual(request.graphPath, "me")
    XCTAssertEqual(request.parameters["fields"] as? String, "id,name")
  }

  func testFetchContentCompleteWithError() throws {
    AccessToken.current = SampleAccessTokens.validToken
    button._fetchAndSetContent()

    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(
      nil,
      [
        "id": SampleAccessTokens.validToken.userID,
        "name": SampleUserProfiles.defaultName,
      ],
      NSError(domain: "foo", code: 0, userInfo: nil)
    )

    XCTAssertNil(button.userID())
    XCTAssertNil(button.userName())
  }

  func testFetchContentCompleteWithNilResponse() throws {
    button._fetchAndSetContent()

    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, nil, nil)

    XCTAssertNil(button.userID())
    XCTAssertNil(button.userName())
  }

  func testFetchContentCompleteWithEmptyResponse() throws {
    button._fetchAndSetContent()

    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, [], nil)

    XCTAssertNil(button.userID())
    XCTAssertNil(button.userName())
  }

  func testFetchContentCompleteWithMatchingUID() throws {
    AccessToken.current = SampleAccessTokens.validToken
    button._fetchAndSetContent()

    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(
      nil,
      [
        "id": SampleAccessTokens.validToken.userID,
        "name": SampleUserProfiles.defaultName,
      ],
      nil
    )

    XCTAssertEqual(button.userID(), SampleAccessTokens.validToken.userID)
    XCTAssertEqual(button.userName(), SampleUserProfiles.defaultName)
  }

  func testFetchContentCompleteWithNonmatchingUID() throws {
    AccessToken.current = SampleAccessTokens.validToken
    button._fetchAndSetContent()

    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)
    completion(
      nil,
      [
        "id": self.name,
        "name": SampleUserProfiles.defaultName,
      ],
      nil
    )

    XCTAssertNil(button.userID())
    XCTAssertNil(button.userName())
  }

  // MARK: - Setting Messenger Page ID

  func testDefaultMessengerPageId() {
    XCTAssertNil(FBLoginButton().messengerPageId, "Should not have a default Messenger Page ID")
  }

  func testSettingMessengerPageId() {
    button.messengerPageId = "1234"

    XCTAssertEqual(
      button.messengerPageId,
      "1234",
      "Should set a valid Messenger Page ID"
    )
  }

  func testLoginConfigurationWithMessengerPageId() {
    button.messengerPageId = "1234"

    XCTAssertNotNil(
      button.loginConfiguration(),
      "Should be able to create a configuration with Messenger Page Id"
    )
  }

  // MARK: - Setting Auth Type

  func testDefaultAuthType() {
    XCTAssertEqual(
      FBLoginButton().authType,
      LoginAuthType.rerequest,
      "Default auth_type should be rerequest"
    )
  }

  func testSettingAuthType() {
    button.authType = .reauthorize

    XCTAssertEqual(
      button.authType,
      .reauthorize,
      "Should set a valid auth type"
    )
  }

  func testLoginConfigurationWithAuthType() {
    button.authType = .reauthorize

    XCTAssertNotNil(
      button.loginConfiguration(),
      "Should be able to create a configuration with auth type"
    )
    XCTAssertEqual(button.loginConfiguration().authType, .reauthorize)
  }

  func testLoginConfigurationWithNilAuthType() {
    button.authType = nil

    XCTAssertNotNil(
      button.loginConfiguration(),
      "Should be able to create a configuration with nil auth type"
    )
    XCTAssertNil(button.loginConfiguration().authType)
  }

  func testLoginConfigurationWithNoAuthType() {
    XCTAssertNotNil(
      button.loginConfiguration(),
      "Should be able to create a configuration with default auth type"
    )
    XCTAssertEqual(button.loginConfiguration().authType, .rerequest)
  }

  // MARK: default audience

  func testDefaultAudience() {
    XCTAssertEqual(
      button.defaultAudience,
      .friends,
      "Should have a default audience of friends"
    )
  }

  func testSettingDefaultAudience() {
    button.defaultAudience = .onlyMe
    XCTAssertEqual(
      button.defaultAudience,
      .onlyMe,
      "Should set the default audience to only me"
    )
    XCTAssertEqual(
      loginProvider.defaultAudience,
      .onlyMe,
      "Should set the default audience of the underlying login provider to only me"
    )
  }

  // MARK: login tracking

  func testDefaultLoginTracking() {
    XCTAssertEqual(
      button.loginTracking,
      .enabled,
      "Should set the default login tracking to be enabled"
    )
  }

  func testSettingLoginTracking() {
    button.loginTracking = .limited
    XCTAssertEqual(
      button.loginTracking,
      .limited,
      "Should set the login tracking to limited"
    )
    XCTAssertEqual(
      button.loginConfiguration().tracking,
      .limited,
      "Should created a login configuration with the expected tracking"
    )
  }

  // MARK: Button Press

  func testButtonPressNotAuthenticatedLoginNotAllowed() throws {
    delegate.shouldLogin = false

    button._buttonPressed(self)

    XCTAssert(delegate.willLogin)

    XCTAssertNil(loginProvider.capturedCompletion)
    XCTAssertNil(loginProvider.capturedConfiguration)
  }

  func testButtonPressNotAuthenticatedLoginAllowed() throws {
    button._buttonPressed(self)

    XCTAssert(delegate.willLogin)

    XCTAssertNotNil(loginProvider.capturedConfiguration)
    let completion = try XCTUnwrap(loginProvider.capturedCompletion)
    let granted = Set(SampleAccessTokens.validToken.permissions.map { $0.name })
    let declined = Set(SampleAccessTokens.validToken.declinedPermissions.map { $0.name })
    let result = LoginManagerLoginResult(
      token: SampleAccessTokens.validToken,
      authenticationToken: sampleToken,
      isCancelled: false,
      grantedPermissions: granted,
      declinedPermissions: declined
    )
    completion(result, nil)

    XCTAssertEqual(delegate.capturedResult, result)
  }

  func testLogout() {
    button._logout()
    XCTAssert(loginProvider.didLogout)
    XCTAssert(delegate.didLoggedOut)
  }
}

private class TestButton: FBLoginButton {
  var fetchAndSetContentCallCount = 0
  var updateContentForAccessTokenCallCount = 0
  var updateContentForProfileCallCount = 0

  override func _updateContentForAccessToken() {
    updateContentForAccessTokenCallCount += 1

    super._updateContentForAccessToken()
  }

  override func _updateContent(forUserProfile profile: Profile?) {
    updateContentForProfileCallCount += 1

    super._updateContent(forUserProfile: profile)
  }

  override func _fetchAndSetContent() {
    fetchAndSetContentCallCount += 1
  }
} // swiftlint:disable:this file_length
