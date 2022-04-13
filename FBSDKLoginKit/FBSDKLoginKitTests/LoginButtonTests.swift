/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import TestTools
import XCTest

final class LoginButtonTests: XCTestCase {

  let validNonce: String = "abc123"
  // swiftlint:disable implicitly_unwrapped_optional
  var loginProvider: TestLoginProvider!
  var stringProvider: TestUserInterfaceStringProvider!
  var elementProvider: TestUserInterfaceElementProvider!
  var graphRequestFactory: TestGraphRequestFactory!
  var loginButton: FBLoginButton!
  var sampleToken: AuthenticationToken!
  var delegate: TestLoginButtonDelegate!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    loginProvider = TestLoginProvider()
    stringProvider = TestUserInterfaceStringProvider()
    elementProvider = TestUserInterfaceElementProvider()
    graphRequestFactory = TestGraphRequestFactory()
    sampleToken = AuthenticationToken(tokenString: "abc", nonce: "123")
    delegate = TestLoginButtonDelegate()
    loginButton = FBLoginButton(
      elementProvider: elementProvider,
      stringProvider: stringProvider,
      loginProvider: loginProvider,
      graphRequestFactory: graphRequestFactory
    )
    loginButton.delegate = delegate
    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    AuthenticationToken.current = nil
    Profile.current = nil
  }

  override func tearDown() {
    loginProvider = nil
    stringProvider = nil
    elementProvider = nil
    graphRequestFactory = nil
    sampleToken = nil
    loginButton = nil
    delegate = nil
    super.tearDown()
  }

  // MARK: - Dependencies

  func testDefaultDependencies() {
    let loginButton = FBLoginButton()
    XCTAssertIdentical(
      loginButton.elementProvider,
      InternalUtility.shared,
      .hasDefaultElementProvider
    )

    XCTAssertIdentical(
      loginButton.stringProvider,
      InternalUtility.shared,
      .hasDefaultStringProvider
    )

    XCTAssertTrue(
      loginButton.loginProvider is LoginManager,
      .hasDefaultLoginProvider
    )

    XCTAssertTrue(
      loginButton.graphRequestFactory is GraphRequestFactory,
      .hasDefaultGraphRequestFactory
    )
  }

  func testCustomDependencies() {
    XCTAssertIdentical(
      loginButton.elementProvider,
      elementProvider,
      .hasCustomElementProvider
    )

    XCTAssertIdentical(
      loginButton.stringProvider,
      stringProvider,
      .hasCustomStringProvider
    )

    XCTAssertIdentical(
      loginButton.loginProvider,
      loginProvider,
      .hasCustomLoginProvider
    )

    XCTAssertIdentical(
      loginButton.graphRequestFactory,
      graphRequestFactory,
      .hasCustomLoginProvider
    )
  }

  // MARK: - Nonce

  func testDefaultNonce() {
    XCTAssertNil(FBLoginButton().nonce, "Should not have a default nonce")
  }

  func testSettingInvalidNonce() {
    loginButton.nonce = "   "

    XCTAssertNil(
      loginButton.nonce,
      "Should not set an invalid nonce"
    )
  }

  func testSettingValidNonce() {
    loginButton.nonce = validNonce

    XCTAssertEqual(
      loginButton.nonce,
      validNonce,
      "Should set a valid nonce"
    )
  }

  func testLoginConfigurationWithoutNonce() {
    XCTAssertNotNil(
      loginButton.loginConfiguration(),
      "Should be able to create a login configuration without a provided nonce"
    )
  }

  func testLoginConfigurationWithInvalidNonce() {
    loginButton.nonce = "   "

    XCTAssertNotNil(
      loginButton.loginConfiguration(),
      "Should not create a login configuration with an invalid nonce"
    )
  }

  func testLoginConfigurationWithValidNonce() {
    loginButton.nonce = validNonce

    XCTAssertEqual(
      loginButton.loginConfiguration()?.nonce,
      validNonce,
      "Should create a login configuration with valid nonce"
    )
  }

  // MARK: - Initial Content Update

  func testInitialContentUpdateWithInactiveAccessTokenWithProfile() {
    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    let profile = SampleUserProfiles.createValid()
    Profile.setCurrent(profile, shouldPostNotification: false)

    loginButton.initializeContent()

    XCTAssertTrue(
      loginButton.isSelected,
      .selectsButtonWithProfile
    )

    XCTAssertEqual(
      loginButton.userName,
      profile.name,
      .setsUserNameWithProfile
    )

    XCTAssertEqual(
      loginButton.userID,
      profile.userID,
      .setsUserIDWithProfile
    )
  }

  func testInitialContentUpdateWithActiveAccessTokenWithProfile() throws {

    AccessToken.setCurrent(SampleAccessTokens.validToken, shouldDispatchNotif: false)
    let profile = SampleUserProfiles.createValid()
    Profile.setCurrent(profile, shouldPostNotification: false)

    loginButton.initializeContent()

    let request = try XCTUnwrap(
      graphRequestFactory.capturedRequests.first,
      .createsRequest
    )

    let result = [
      "id": SampleAccessTokens.validToken.userID,
      "name": SampleUserProfiles.defaultName,
    ]

    let completion = try XCTUnwrap(
      graphRequestFactory.capturedRequests.first?.capturedCompletionHandler,
      .createsRequest
    )

    completion(
      nil,
      result,
      nil
    )

    XCTAssertTrue(
      loginButton.isSelected,
      .selectsButtonWithAccessToken
    )

    XCTAssertEqual(request.graphPath, "me", .createsRequest)

    XCTAssertEqual(
      request.parameters["fields"] as? String,
      "id,name",
      .createsRequestWithParameters
    )

    XCTAssertEqual(
      loginButton.userName,
      result["name"],
      .setsUserNameWithAccessToken
    )

    XCTAssertEqual(
      loginButton.userID,
      result["id"],
      .setsUserIDWithAccessToken
    )
  }

  func testInitialContentUpdateWithoutAccessTokenWithoutProfile() {
    AccessToken.setCurrent(nil, shouldDispatchNotif: false)
    Profile.setCurrent(nil, shouldPostNotification: false)

    loginButton.initializeContent()

    XCTAssertFalse(
      loginButton.isSelected,
      .doesNotSelectsButtonWithoutAccessToken
    )
  }

  // MARK: - Determining Authentication Status

  func testDeterminingAuthenticationWithAccessTokenWithoutAuthToken() {
    AccessToken.setCurrent(SampleAccessTokens.validToken, shouldDispatchNotif: false)

    XCTAssertTrue(
      loginButton.isAuthenticated,
      "Should consider a user authenticated if they have a current access token"
    )
  }

  func testDeterminingAuthenticationWithoutAccessTokenWithAuthToken() {
    AuthenticationToken.current = sampleToken

    XCTAssertTrue(
      loginButton.isAuthenticated,
      "Should consider a user authenticated if they have a current authentication token"
    )
  }

  // MARK: - Handling Notifications

  func testReceivingAccessTokenNotificationWithDidChangeUserIdKey() throws {
    let notification = Notification(
      name: .AccessTokenDidChange,
      object: nil,
      userInfo: [AccessTokenDidChangeUserIDKey: "foo"]
    )

    AccessToken.setCurrent(SampleAccessTokens.validToken, shouldDispatchNotif: false)
    loginButton.accessTokenDidChange(notification)

    let request = try XCTUnwrap(
      graphRequestFactory.capturedRequests.first,
      .createsRequest
    )

    let result = [
      "id": SampleAccessTokens.validToken.userID,
      "name": SampleUserProfiles.defaultName,
    ]

    let completion = try XCTUnwrap(
      graphRequestFactory.capturedRequests.first?.capturedCompletionHandler,
      .createsRequest
    )

    completion(
      nil,
      result,
      nil
    )

    XCTAssertTrue(
      loginButton.isSelected,
      .selectsButtonNotificationUserIdKey
    )

    XCTAssertEqual(request.graphPath, "me", .createsRequest)

    XCTAssertEqual(
      request.parameters["fields"] as? String,
      "id,name",
      .createsRequestWithParameters
    )

    XCTAssertEqual(
      loginButton.userName,
      result["name"],
      .setsUserNameWithNotificationUserIdKey
    )

    XCTAssertEqual(
      loginButton.userID,
      result["id"],
      .setsUserIDWithNotificationUserIdKey
    )
  }

  func testReceivingAccessTokenNotificationWithTokenDidExpireKey() {
    let notification = Notification(
      name: .AccessTokenDidChange,
      object: nil,
      userInfo: [AccessTokenDidExpireKey: "foo"]
    )

    loginButton.accessTokenDidChange(notification)

    XCTAssertFalse(
      loginButton.isSelected,
      .doesNotSelectsButtonWithExpiredKey
    )
  }

  func testReceivingAccessTokenNotificationWithoutRelevantUserInfo() {
    let notification = Notification(
      name: .AccessTokenDidChange,
      object: nil,
      userInfo: nil
    )

    loginButton.isSelected = true
    let profile = SampleUserProfiles.createValid(userID: SampleAccessTokens.validToken.userID)

    loginButton.updateContentForUser(profile)
    loginButton.accessTokenDidChange(notification)

    XCTAssertTrue(
      loginButton.isSelected,
      .doesNotChangeButtonStateWithoutUserInfo
    )

    XCTAssertEqual(
      loginButton.userName,
      profile.name,
      .doesNotChangeUserNameWithoutUserInfo
    )

    XCTAssertEqual(
      loginButton.userID,
      profile.userID,
      .doesNotChangeUserIDWithoutUserInfo
    )

    loginButton.isSelected = false
    loginButton.accessTokenDidChange(notification)

    XCTAssertFalse(
      loginButton.isSelected,
      .doesNotChangeButtonStateWithoutUserInfo
    )
  }

  func testReceivingProfileNotificationWithNoProfile() {
    let notification = Notification(
      name: .ProfileDidChange,
      object: nil,
      userInfo: nil
    )
    let oldUserName = loginButton.userName
    let oldUserId = loginButton.userID

    loginButton.profileDidChange(notification)

    XCTAssertFalse(
      loginButton.isSelected,
      .doesNotSelectsButtonWithNoProfileNotification
    )

    XCTAssertEqual(
      loginButton.userName,
      oldUserName,
      .doesNotChangeUserNameWithNoProfileNotification
    )

    XCTAssertEqual(
      loginButton.userID,
      oldUserId,
      .doesNotChangeUserIDWithNoProfileNotification
    )
  }

  func testReceivingProfileNotificationWithProfile() {
    let notification = Notification(
      name: .ProfileDidChange,
      object: nil,
      userInfo: nil
    )

    let profile = SampleUserProfiles.createValid()
    Profile.setCurrent(profile, shouldPostNotification: false)

    loginButton.profileDidChange(notification)

    XCTAssertTrue(
      loginButton.isSelected,
      .selectsButtonWithProfileNotification
    )

    XCTAssertEqual(
      loginButton.userName,
      profile.name,
      .setsUserNameWithProfileNotification
    )

    XCTAssertEqual(
      loginButton.userID,
      profile.userID,
      .setsUserIDWithProfileNotification
    )
  }

  func testReceivingProfileNotificationWithSameProfile() {
    let notification = Notification(
      name: .ProfileDidChange,
      object: nil,
      userInfo: nil
    )

    let profile = SampleUserProfiles.createValid()
    Profile.setCurrent(profile, shouldPostNotification: false)
    loginButton.updateContentForUser(profile)
    loginButton.profileDidChange(notification)

    XCTAssertTrue(
      loginButton.isSelected,
      .selectsButtonWithProfileNotification
    )

    XCTAssertEqual(
      loginButton.userName,
      profile.name,
      .doesNotChangeUserNameWithSameProfile
    )

    XCTAssertEqual(
      loginButton.userID,
      profile.userID,
      .doesNotChangeUserIdWithSameProfile
    )
  }

  // MARK: - Updating Content

  func testUpdatingContentWithMissingProfile() {
    loginButton.updateContentForUser(nil)

    XCTAssertFalse(
      loginButton.isSelected,
      "Should not be selected if there is not a profile"
    )
    XCTAssertNil(loginButton.userName)
    XCTAssertNil(loginButton.userID)
  }

  func testUpdatingContentWithProfile() {
    let profile = SampleUserProfiles.createValid()
    loginButton.updateContentForUser(profile)

    XCTAssertTrue(
      loginButton.isSelected,
      "Should be selected if there is a valid profile"
    )
    XCTAssertEqual(loginButton.userName, profile.name)
    XCTAssertEqual(loginButton.userID, profile.userID)
  }

  func testUpdatingContentForProfileWithNewId() {
    let profile = SampleUserProfiles.createValid(userID: "345")
    loginButton.updateContentForUser(SampleUserProfiles.createValid())
    loginButton.updateContentForUser(profile)

    XCTAssertTrue(
      loginButton.isSelected,
      .selectsButtonForProfileWithNewId
    )

    XCTAssertEqual(
      loginButton.userName,
      profile.name,
      .updatesUserNameForProfileWithNewId
    )

    XCTAssertEqual(
      loginButton.userID,
      profile.userID,
      .updatesUserIdForProfileWithNewId
    )
  }

  func testUpdatingContentForProfileWithNewName() {
    let profile = SampleUserProfiles.createValid(userID: "345")

    loginButton.updateContentForUser(SampleUserProfiles.createValid(userID: "345", name: "Paul Smith"))

    loginButton.updateContentForUser(profile)

    XCTAssertTrue(
      loginButton.isSelected,
      .selectsButtonForProfileWithNewName
    )

    XCTAssertEqual(
      loginButton.userName,
      profile.name,
      .updatesUserNameForProfileWithNewName
    )
    XCTAssertEqual(
      loginButton.userID,
      profile.userID,
      .updatesUserIdForProfileWithNewName
    )
  }

  func testUpdatingContentWithValidAccessToken() throws {
    AccessToken.setCurrent(SampleAccessTokens.validToken, shouldDispatchNotif: false)

    loginButton.updateContentForAccessToken()

    let request = try XCTUnwrap(
      graphRequestFactory.capturedRequests.first,
      .createsRequest
    )

    let result = [
      "id": SampleAccessTokens.validToken.userID,
      "name": SampleUserProfiles.defaultName,
    ]

    let completion = try XCTUnwrap(
      graphRequestFactory.capturedRequests.first?.capturedCompletionHandler,
      .createsRequest
    )

    completion(
      nil,
      result,
      nil
    )

    XCTAssertTrue(
      loginButton.isSelected,
      .selectsButtonWithAccessTokenUpdate
    )

    XCTAssertEqual(request.graphPath, "me", .createsRequest)
    XCTAssertEqual(
      request.parameters["fields"] as? String,
      "id,name",
      .createsRequestWithParameters
    )

    XCTAssertEqual(
      loginButton.userName,
      result["name"],
      .updatesUserNameWithAccessToken
    )

    XCTAssertEqual(
      loginButton.userID,
      result["id"],
      .updatesUserIDWithAccessToken
    )
  }

  func testUpdatingContentWithInvalidAccessToken() {
    AccessToken.setCurrent(SampleAccessTokens.expiredToken, shouldDispatchNotif: false)

    loginButton.updateContentForAccessToken()

    XCTAssertFalse(
      loginButton.isSelected,
      .doesNotSelectButtonWithInvalidAccessToken
    )
  }

  func testUpdatingContentWithIdenticalAccessToken() {
    // Make sure the username and id properties on button are set to the same values
    // as the access token. This is an easy way to do with without having to stub
    // a network call
    let profile = SampleUserProfiles.createValid(userID: SampleAccessTokens.validToken.userID)
    loginButton.updateContentForUser(profile)

    AccessToken.setCurrent(SampleAccessTokens.validToken, shouldDispatchNotif: false)

    loginButton.updateContentForAccessToken()

    XCTAssertTrue(
      loginButton.isSelected,
      .selectsButtonWithIdenticalAccessToken
    )

    XCTAssertEqual(
      loginButton.userName,
      profile.name,
      .doesNotChangeUserNameWithIdenticalAccessToken
    )

    XCTAssertEqual(
      loginButton.userID,
      profile.userID,
      .doesNotChangeUserIdWithIdenticalAccessToken
    )
  }

  // MARK: - Fetching Content

  func testFetchContentGraphRequestCreation() throws {
    loginButton.fetchAndSetContent()

    let request = try XCTUnwrap(graphRequestFactory.capturedRequests.first)
    XCTAssertEqual(request.graphPath, "me")
    XCTAssertEqual(request.parameters["fields"] as? String, "id,name")
  }

  func testFetchContentCompleteWithError() throws {
    AccessToken.current = SampleAccessTokens.validToken
    loginButton.fetchAndSetContent()

    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(
      nil,
      [
        "id": SampleAccessTokens.validToken.userID,
        "name": SampleUserProfiles.defaultName,
      ],
      NSError(domain: "foo", code: 0, userInfo: nil)
    )

    XCTAssertNil(loginButton.userID)
    XCTAssertNil(loginButton.userName)
  }

  func testFetchContentCompleteWithNilResponse() throws {
    loginButton.fetchAndSetContent()

    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, nil, nil)

    XCTAssertNil(loginButton.userID)
    XCTAssertNil(loginButton.userName)
  }

  func testFetchContentCompleteWithEmptyResponse() throws {
    loginButton.fetchAndSetContent()

    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, [], nil)

    XCTAssertNil(loginButton.userID)
    XCTAssertNil(loginButton.userName)
  }

  func testFetchContentCompleteWithMatchingUID() throws {
    AccessToken.current = SampleAccessTokens.validToken
    loginButton.fetchAndSetContent()

    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(
      nil,
      [
        "id": SampleAccessTokens.validToken.userID,
        "name": SampleUserProfiles.defaultName,
      ],
      nil
    )

    XCTAssertEqual(loginButton.userID, SampleAccessTokens.validToken.userID)
    XCTAssertEqual(loginButton.userName, SampleUserProfiles.defaultName)
  }

  func testFetchContentCompleteWithNonmatchingUID() throws {
    AccessToken.current = SampleAccessTokens.validToken
    loginButton.fetchAndSetContent()

    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(
      nil,
      [
        "id": name,
        "name": SampleUserProfiles.defaultName,
      ],
      nil
    )

    XCTAssertNil(loginButton.userID)
    XCTAssertNil(loginButton.userName)
  }

  // MARK: - Setting Messenger Page ID

  func testDefaultMessengerPageId() {
    XCTAssertNil(FBLoginButton().messengerPageId, "Should not have a default Messenger Page ID")
  }

  func testSettingMessengerPageId() {
    loginButton.messengerPageId = "1234"

    XCTAssertEqual(
      loginButton.messengerPageId,
      "1234",
      "Should set a valid Messenger Page ID"
    )
  }

  func testLoginConfigurationWithMessengerPageId() {
    loginButton.messengerPageId = "1234"

    XCTAssertNotNil(
      loginButton.loginConfiguration(),
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
    loginButton.authType = .reauthorize

    XCTAssertEqual(
      loginButton.authType,
      .reauthorize,
      "Should set a valid auth type"
    )
  }

  func testLoginConfigurationWithAuthType() {
    loginButton.authType = .reauthorize

    XCTAssertNotNil(
      loginButton.loginConfiguration(),
      "Should be able to create a configuration with auth type"
    )
    XCTAssertEqual(loginButton.loginConfiguration()?.authType, .reauthorize)
  }

  func testLoginConfigurationWithNilAuthType() {
    loginButton.authType = nil

    XCTAssertNotNil(
      loginButton.loginConfiguration(),
      "Should be able to create a configuration with nil auth type"
    )
    XCTAssertNil(loginButton.loginConfiguration()?.authType)
  }

  func testLoginConfigurationWithNoAuthType() {
    XCTAssertNotNil(
      loginButton.loginConfiguration(),
      "Should be able to create a configuration with default auth type"
    )
    XCTAssertEqual(loginButton.loginConfiguration()?.authType, .rerequest)
  }

  // MARK: default audience

  func testDefaultAudience() {
    XCTAssertEqual(
      loginButton.defaultAudience,
      .friends,
      "Should have a default audience of friends"
    )
  }

  func testSettingDefaultAudience() {
    loginButton.defaultAudience = .onlyMe
    XCTAssertEqual(
      loginButton.defaultAudience,
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
      loginButton.loginTracking,
      .enabled,
      "Should set the default login tracking to be enabled"
    )
  }

  func testSettingLoginTracking() {
    loginButton.loginTracking = .limited
    XCTAssertEqual(
      loginButton.loginTracking,
      .limited,
      "Should set the login tracking to limited"
    )
    XCTAssertEqual(
      loginButton.loginConfiguration()?.tracking,
      .limited,
      "Should created a login configuration with the expected tracking"
    )
  }

  // MARK: Code Verifier

  func testSettingCodeVerifier() {
    let codeVerifier = CodeVerifier()
    loginButton.codeVerifier = codeVerifier
    XCTAssertEqual(
      loginButton.codeVerifier.value,
      codeVerifier.value,
      "Should set the code verifier to the expected value"
    )
    XCTAssertEqual(
      loginButton.loginConfiguration()?.codeVerifier.value,
      codeVerifier.value,
      "Should create a login configuration with the expected code verifier"
    )
  }

  func testDefaultCodeVerifier() {
    XCTAssertNotNil(
      loginButton.codeVerifier,
      "Default code verifier should not be nil"
    )
    XCTAssertNotNil(
      loginButton.loginConfiguration()?.codeVerifier,
      "Should create a login configuration with the default code verifier"
    )
  }

  // MARK: Button Press

  func testButtonPressNotAuthenticatedLoginNotAllowed() throws {
    delegate.shouldLogin = false

    loginButton.buttonPressed(self)

    XCTAssert(delegate.willLogin)

    XCTAssertNil(loginProvider.capturedCompletion)
    XCTAssertNil(loginProvider.capturedConfiguration)
  }

  func testButtonPressNotAuthenticatedLoginAllowed() throws {
    loginButton.buttonPressed(self)

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

  func testButtonPressAuthenticated() throws {
    AuthenticationToken.current = sampleToken
    let rootVC = UIViewController()
    elementProvider.stubbedTopMostViewController = rootVC

    let window = UIWindow()
    window.rootViewController = rootVC
    window.makeKeyAndVisible()
    rootVC.view.addSubview(loginButton)

    loginButton.buttonPressed(self)

    let presentedVC = try XCTUnwrap(window.rootViewController?.presentedViewController, .showsAlertViewController)

    XCTAssertTrue(
      presentedVC is UIAlertController,
      .showsAlertViewController
    )
  }

  func testLogout() {
    loginButton.logout()
    XCTAssert(loginProvider.didLogout)
    XCTAssert(delegate.didLoggedOut)
  }

  // MARK: - Tooltip

  func testShowTooltipIfNeeded() {
    let button = FBLoginButton()
    button.tooltipBehavior = .forceDisplay

    let window = UIWindow()
    let rootVC = UIViewController()
    window.rootViewController = rootVC
    window.makeKeyAndVisible()
    rootVC.view.addSubview(button)

    if !rootVC.view.subviews.contains(where: { $0 is FBLoginTooltipView }) {
      XCTFail(.showsTooltip)
    }
  }

  func testShowTooltipIfNeededWithAuthenticated() {
    AuthenticationToken.current = sampleToken

    let button = FBLoginButton()
    button.tooltipBehavior = .forceDisplay

    let window = UIWindow()
    let rootVC = UIViewController()
    window.rootViewController = rootVC
    window.makeKeyAndVisible()
    rootVC.view.addSubview(button)

    if rootVC.view.subviews.contains(where: { $0 is FBLoginTooltipView }) {
      XCTFail(.doesNotShowTooltipForAuthenticated)
    }
  }

  func testShowTooltipIfNeededWithDisabledBehavior() {
    let button = FBLoginButton()
    button.tooltipBehavior = .disable

    let window = UIWindow()
    let rootVC = UIViewController()
    window.rootViewController = rootVC
    window.makeKeyAndVisible()
    rootVC.view.addSubview(button)

    if rootVC.view.subviews.contains(where: { $0 is FBLoginTooltipView }) {
      XCTFail(.doesNotShowTooltipIfDisabled)
    }
  }

  // MARK: - Layout

  func testImageRectForContentRect() {

    let contentRect = CGRect(x: 0, y: 0, width: 100, height: 100)
    let imageRect = loginButton.imageRect(forContentRect: contentRect)
    let expectedImageRect = CGRect(x: 6.0, y: 42.0, width: 16.0, height: 16.0)

    XCTAssertEqual(
      imageRect,
      expectedImageRect,
      .hasCustomImageFrame
    )
  }

  func testTitleRectForContentRect() {

    let contentRect = CGRect(x: 0, y: 0, width: 100, height: 100)
    loginButton.frame = contentRect
    let titleRect = loginButton.titleRect(forContentRect: contentRect)
    let expectedTitleRect = CGRect(x: 30.0, y: 0.0, width: 62.0, height: 100.0)

    XCTAssertEqual(
      titleRect,
      expectedTitleRect,
      .hasCustomTitleFrame
    )
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let hasCustomImageFrame = """
    The image frame for a button should be vertically centered and \
    given left padding of 6 points and sized like the logo
    """
  static let hasCustomTitleFrame = """
    The title frame for a button should have a 8 points horizontal padding and no vertical padding. \
    Size should be as big as content frame minus paddings and image frame
    """
  static let showsTooltip = "Shows a tooltip if user is not authenticated or tooltip is not disabled"
  static let doesNotShowTooltipForAuthenticated = "Does not show a tooltip if user is authenticated"
  static let doesNotShowTooltipIfDisabled = "Does not show a tooltip if tooltip has been disabled"
  static let showsAlertViewController = """
    Shows an alert view controller when the login button is pressed, if the user is already authenticated
    """
  static let hasDefaultElementProvider = """
    Should have a default element provider dependency
    """
  static let hasDefaultStringProvider = """
    Should have a default string provider dependency
    """
  static let hasDefaultLoginProvider = """
    Should have a default login provider dependency
    """
  static let hasDefaultGraphRequestFactory = """
    Should have a default graph request factory dependency
    """
  static let hasCustomElementProvider = """
    Should have a custom element provider dependency
    """
  static let hasCustomStringProvider = """
    Should have a custom string provider dependency
    """
  static let hasCustomLoginProvider = """
    Should have a custom login provider dependency
    """
  static let hasCustomGraphRequestFactory = """
    Should have a custom graph request factory dependency
    """
  static let selectsButtonWithProfile = """
    Login button should be selected when initializing content \
    and using a profile
    """
  static let setsUserNameWithProfile = """
    User name should be set when initializing content \
    and using a profile
    """
  static let setsUserIDWithProfile = """
    User id should be set when initializing content \
    and using a profile
    """
  static let selectsButtonWithAccessToken = """
    Login button should be selected when initializing content \
    and using an access token
    """
  static let setsUserNameWithAccessToken = """
    User name should be set when initializing content \
    and using an access token
    """
  static let setsUserIDWithAccessToken = """
    User id should be set when initializing content \
    and using an access token
    """
  static let createsRequest = """
    Should create a request with the expected path
    """
  static let createsRequestWithParameters = """
    Should create a request with the expected parameters
    """
  static let doesNotSelectsButtonWithoutAccessToken = """
    Login button should not be selected when there is no access token \
    or current profile
    """
  static let selectsButtonNotificationUserIdKey = """
    Login button should be selected when we receive an access token \
    change notification with a user id key
    """
  static let setsUserNameWithNotificationUserIdKey = """
    User name should be equal to user name we received in the response \
    after we receive an access token change notification with \
    a user id key
    """
  static let setsUserIDWithNotificationUserIdKey = """
    User id should be equal to user id we received in the response \
    after we receive an access token change notification with \
    a user id key
    """
  static let doesNotSelectsButtonWithExpiredKey = """
    Login button should not be selected after we receive an \
    access token change notification with an expired key
    """
  static let doesNotChangeButtonStateWithoutUserInfo = """
    Login button should not change current state after we \
    receive an access token change notification with no user info
    """
  static let doesNotChangeUserNameWithoutUserInfo = """
    User name should not change after we receive an \
    access token change notification with no user info
    """
  static let doesNotChangeUserIDWithoutUserInfo = """
    User id should not change after we receive an \
    access token change notification with no user info
    """
  static let selectsButtonWithProfileNotification = """
    Login button should be selected after we receive a \
    profile change notification with a valid profile
    """
  static let setsUserNameWithProfileNotification = """
    User name should be changed after we receive a \
    profile change notification with a different profile
    """
  static let setsUserIDWithProfileNotification = """
    User id should be changed after we receive a \
    profile change notification with a different profile
    """
  static let doesNotSelectsButtonWithNoProfileNotification = """
    Login button should not be selected after we receive a \
    profile change notification and there is no profile
    """
  static let doesNotChangeUserNameWithNoProfileNotification = """
    User name should not change after we receive a \
    profile change notification and there is no profile
    """
  static let doesNotChangeUserIDWithNoProfileNotification = """
    User id should not change after we receive a \
    profile change notification and there is no profile
    """
  static let doesNotChangeUserNameWithSameProfile = """
    User name should change after we receive a \
    profile change notification with same profile
    """
  static let doesNotChangeUserIdWithSameProfile = """
    User id should change after we receive a \
    profile change notification with same profile
    """
  static let selectsButtonWithAccessTokenUpdate = """
    Login button should be selected when updating content \
    and using an access token
    """
  static let updatesUserNameWithAccessToken = """
    User name should be set when updating content \
    and using an access token
    """
  static let updatesUserIDWithAccessToken = """
    User id should be set when updating content \
    and using an access token
    """
  static let doesNotSelectButtonWithInvalidAccessToken = """
    Login button should not be selected when updating content \
    and using an invalid access token
    """
  static let selectsButtonWithIdenticalAccessToken = """
    Login button should be selected when attempting to update content \
    with an identical access token
    """
  static let doesNotChangeUserNameWithIdenticalAccessToken = """
    User name should not change when attempting to update content \
    with an identical access token
    """
  static let doesNotChangeUserIdWithIdenticalAccessToken = """
    User id should not change when attempting to update content \
    with an identical access token
    """
  static let selectsButtonForProfileWithNewId = """
    Login button should be selected when attempting to update content \
    with a profile with a new user id
    """
  static let updatesUserNameForProfileWithNewId = """
    User name should change when attempting to update content \
    with a profile with a new user id
    """
  static let updatesUserIdForProfileWithNewId = """
    User id should change when attempting to update content \
    with a profile with a new user id
    """
  static let selectsButtonForProfileWithNewName = """
    Login button should be selected when attempting to update content \
    with a profile with an identical user id but has a new name
    """
  static let updatesUserNameForProfileWithNewName = """
    User name should change when attempting to update content \
    with a profile with an identical user id has a new name
    """
  static let updatesUserIdForProfileWithNewName = """
    User id should change when attempting to update content \
    with a profile with an identical user id has a new name
    """
}
