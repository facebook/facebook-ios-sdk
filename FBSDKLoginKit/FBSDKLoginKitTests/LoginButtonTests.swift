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
    loginButton = FBLoginButton()
    loginButton.configure(
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
      loginButton.loginConfiguration().nonce,
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
      loginButton._isAuthenticated(),
      "Should consider a user authenticated if they have a current access token"
    )
  }

  func testDeterminingAuthenticationWithoutAccessTokenWithAuthToken() {
    AuthenticationToken.current = sampleToken

    XCTAssertTrue(
      loginButton._isAuthenticated(),
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
    loginButton._updateContent(forUserProfile: nil)

    XCTAssertFalse(
      loginButton.isSelected,
      "Should not be selected if there is not a profile"
    )
    XCTAssertNil(loginButton.userName())
    XCTAssertNil(loginButton.userID())
  }

  func testUpdatingContentWithProfile() {
    let profile = SampleUserProfiles.createValid()
    loginButton._updateContent(forUserProfile: profile)

    XCTAssertTrue(
      loginButton.isSelected,
      "Should be selected if there is a valid profile"
    )
    XCTAssertEqual(loginButton.userName(), profile.name)
    XCTAssertEqual(loginButton.userID(), profile.userID)
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
    loginButton._fetchAndSetContent()

    let request = try XCTUnwrap(graphRequestFactory.capturedRequests.first)
    XCTAssertEqual(request.graphPath, "me")
    XCTAssertEqual(request.parameters["fields"] as? String, "id,name")
  }

  func testFetchContentCompleteWithError() throws {
    AccessToken.current = SampleAccessTokens.validToken
    loginButton._fetchAndSetContent()

    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(
      nil,
      [
        "id": SampleAccessTokens.validToken.userID,
        "name": SampleUserProfiles.defaultName,
      ],
      NSError(domain: "foo", code: 0, userInfo: nil)
    )

    XCTAssertNil(loginButton.userID())
    XCTAssertNil(loginButton.userName())
  }

  func testFetchContentCompleteWithNilResponse() throws {
    loginButton._fetchAndSetContent()

    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, nil, nil)

    XCTAssertNil(loginButton.userID())
    XCTAssertNil(loginButton.userName())
  }

  func testFetchContentCompleteWithEmptyResponse() throws {
    loginButton._fetchAndSetContent()

    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(nil, [], nil)

    XCTAssertNil(loginButton.userID())
    XCTAssertNil(loginButton.userName())
  }

  func testFetchContentCompleteWithMatchingUID() throws {
    AccessToken.current = SampleAccessTokens.validToken
    loginButton._fetchAndSetContent()

    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(
      nil,
      [
        "id": SampleAccessTokens.validToken.userID,
        "name": SampleUserProfiles.defaultName,
      ],
      nil
    )

    XCTAssertEqual(loginButton.userID(), SampleAccessTokens.validToken.userID)
    XCTAssertEqual(loginButton.userName(), SampleUserProfiles.defaultName)
  }

  func testFetchContentCompleteWithNonmatchingUID() throws {
    AccessToken.current = SampleAccessTokens.validToken
    loginButton._fetchAndSetContent()

    let completion = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completion(
      nil,
      [
        "id": name,
        "name": SampleUserProfiles.defaultName,
      ],
      nil
    )

    XCTAssertNil(loginButton.userID())
    XCTAssertNil(loginButton.userName())
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
    XCTAssertEqual(loginButton.loginConfiguration().authType, .reauthorize)
  }

  func testLoginConfigurationWithNilAuthType() {
    loginButton.authType = nil

    XCTAssertNotNil(
      loginButton.loginConfiguration(),
      "Should be able to create a configuration with nil auth type"
    )
    XCTAssertNil(loginButton.loginConfiguration().authType)
  }

  func testLoginConfigurationWithNoAuthType() {
    XCTAssertNotNil(
      loginButton.loginConfiguration(),
      "Should be able to create a configuration with default auth type"
    )
    XCTAssertEqual(loginButton.loginConfiguration().authType, .rerequest)
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
      loginButton.loginConfiguration().tracking,
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
      loginButton.loginConfiguration().codeVerifier.value,
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
      loginButton.loginConfiguration().codeVerifier,
      "Should create a login configuration with the default code verifier"
    )
  }

  // MARK: Button Press

  func testButtonPressNotAuthenticatedLoginNotAllowed() throws {
    delegate.shouldLogin = false

    loginButton._buttonPressed(self)

    XCTAssert(delegate.willLogin)

    XCTAssertNil(loginProvider.capturedCompletion)
    XCTAssertNil(loginProvider.capturedConfiguration)
  }

  func testButtonPressNotAuthenticatedLoginAllowed() throws {
    loginButton._buttonPressed(self)

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

    loginButton._buttonPressed(self)

    let presentedVC = try XCTUnwrap(window.rootViewController?.presentedViewController, .showsAlertViewController)

    XCTAssertTrue(
      presentedVC is UIAlertController,
      .showsAlertViewController
    )
  }

  func testLogout() {
    loginButton._logout()
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

    if !rootVC.view.subviews.contains(where: { $0 is FBTooltipView }) {
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

    if rootVC.view.subviews.contains(where: { $0 is FBTooltipView }) {
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

    if rootVC.view.subviews.contains(where: { $0 is FBTooltipView }) {
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

private final class TestButton: FBLoginButton {
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
}
