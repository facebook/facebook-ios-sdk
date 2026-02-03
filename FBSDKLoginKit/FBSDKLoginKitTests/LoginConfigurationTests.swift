/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import XCTest

final class LoginConfigurationTests: XCTestCase {

  func testDefaults() {
    guard let configuration = LoginConfiguration() else {
      return XCTFail("Should be able to create a configuration with default arguments")
    }

    XCTAssertEqual(
      configuration.requestedPermissions,
      [],
      "A configuration should be created with default requested permissions"
    )
    XCTAssertEqual(
      configuration.tracking,
      .enabled,
      "Tracking should default to enabled when unspecified"
    )
    XCTAssertEqual(
      configuration.appSwitch,
      .enabled,
      "App switch should default to enabled when unspecified (opt-out model)"
    )
    XCTAssertNotNil(
      configuration.nonce,
      "A configuration should be created with a default nonce"
    )
    XCTAssertNil(
      configuration.messengerPageId,
      "Messenger Page Id should default to nil when unspecified"
    )
    XCTAssertEqual(
      configuration.authType,
      .rerequest,
      "Auth Type should default to rerequest when unspecified"
    )
    XCTAssertNotNil(
      configuration.codeVerifier,
      "A configuration should be created with a default code verifier"
    )
  }

  func testCreatingWithNonceString() {
    let nonce = "12345"
    let configuration = LoginConfiguration(nonce: nonce)
    XCTAssertEqual(
      configuration?.nonce,
      nonce,
      "Should create a configuration with the provided nonce string"
    )
  }

  func testCreatingWithInvalidNonce() {
    XCTAssertNil(
      LoginConfiguration(nonce: " "),
      "Should not create a login configuration with an invalid nonce"
    )
  }

  func testCreatingWithTracking() {
    let preferences = [
      LoginTracking.enabled,
      .limited,
    ]
    preferences.forEach { preference in
      let configuration = LoginConfiguration(tracking: preference)
      XCTAssertEqual(
        configuration?.tracking,
        preference,
        "Should create a configuration with the provided tracking preference"
      )
    }
  }

  func testCreatingWithRequestedPermissions() {
    let permissions = Set([Permission.email, .userLikes])
    let configuration = LoginConfiguration(permissions: permissions)

    XCTAssertEqual(
      Set((configuration?.requestedPermissions.map { $0.value })!), // swiftlint:disable:this force_unwrapping
      Set(permissions.map { $0.name }),
      "Should create a configuration with the provided tracking preference"
    )
  }

  func testCreatingWithMessengerPageId() {
    let messengerPageId = "12345"
    let configuration = LoginConfiguration(messengerPageId: messengerPageId)
    XCTAssertEqual(
      configuration?.messengerPageId,
      messengerPageId,
      .createsConfigWithMessengerID
    )
  }

  func testCreatingWithPermissionsTrackingAndMessengerPageId() {
    let messengerPageId = "12345"
    let permissions = ["email"]

    let configuration = LoginConfiguration(
      permissions: permissions,
      tracking: .enabled,
      messengerPageId: messengerPageId
    )

    XCTAssertEqual(
      configuration?.requestedPermissions,
      FBPermission.permissions(fromRawPermissions: Set(permissions)),
      .createsConfigWithMessengerID
    )

    XCTAssertEqual(
      configuration?.tracking,
      LoginTracking.enabled,
      .createsConfigWithMessengerID
    )

    XCTAssertEqual(
      configuration?.messengerPageId,
      messengerPageId,
      .createsConfigWithMessengerID
    )
  }

  func testCreatingWithRerequestAuthType() {
    let authType = LoginAuthType.rerequest
    let configuration = LoginConfiguration(authType: authType)
    XCTAssertEqual(
      configuration?.authType,
      authType,
      .createsConfigWithAuthType
    )
  }

  func testCreatingWithPermissionsTrackingAndAuthType() {
    let authType = LoginAuthType.rerequest
    let permissions = ["email"]
    let messengerPageId = "12345"

    let configuration = LoginConfiguration(
      permissions: permissions,
      tracking: .enabled,
      messengerPageId: messengerPageId,
      authType: authType
    )

    XCTAssertEqual(
      configuration?.requestedPermissions,
      FBPermission.permissions(fromRawPermissions: Set(permissions)),
      .createsConfigWithAuthType
    )

    XCTAssertEqual(
      configuration?.tracking,
      LoginTracking.enabled,
      .createsConfigWithAuthType
    )

    XCTAssertEqual(
      configuration?.messengerPageId,
      messengerPageId,
      .createsConfigWithAuthType
    )

    XCTAssertEqual(
      configuration?.authType,
      authType,
      .createsConfigWithAuthType
    )
  }

  func testCreatingWithReauthorizeAuthType() {
    let authType = LoginAuthType.reauthorize
    let configuration = LoginConfiguration(authType: authType)
    XCTAssertEqual(
      configuration?.authType,
      authType,
      "Should create a configuration with the provided auth_type"
    )
  }

  func testCreatingWithNilAuthType() {
    let configuration = LoginConfiguration(authType: nil)
    XCTAssertNil(
      configuration?.authType,
      "Should treat a nil auth type as nil"
    )
  }

  func testCreatingWithCodeVerifier() {
    let codeVerifier = CodeVerifier()
    let configuration = LoginConfiguration(permissions: [], codeVerifier: codeVerifier)
    XCTAssertEqual(
      configuration?.codeVerifier.value,
      codeVerifier.value,
      "Should create a configuration with the provided code verifier"
    )
  }

  // MARK: - AppSwitch Tests

  func testCreatingWithAppSwitchEnabled() {
    let configuration = LoginConfiguration(appSwitch: .enabled)
    XCTAssertEqual(
      configuration?.appSwitch,
      .enabled,
      "Should create a configuration with enabled app switch (opt-in)"
    )
  }

  func testCreatingWithAppSwitchDisabled() {
    let configuration = LoginConfiguration(appSwitch: .disabled)
    XCTAssertEqual(
      configuration?.appSwitch,
      .disabled,
      "Should create a configuration with disabled app switch"
    )
  }

  func testCreatingWithAllParametersIncludingAppSwitch() {
    let permissions = ["email", "public_profile"]
    let tracking = LoginTracking.enabled
    let nonce = "test_nonce_12345"
    let messengerPageId = "messenger_page_123"
    let authType = LoginAuthType.rerequest
    let appSwitch = AppSwitch.disabled
    let codeVerifier = CodeVerifier()

    let configuration = LoginConfiguration(
      permissions: permissions,
      tracking: tracking,
      nonce: nonce,
      messengerPageId: messengerPageId,
      authType: authType,
      appSwitch: appSwitch,
      codeVerifier: codeVerifier
    )

    XCTAssertNotNil(configuration, "Should create a configuration with all parameters")
    XCTAssertEqual(
      configuration?.requestedPermissions,
      FBPermission.permissions(fromRawPermissions: Set(permissions)),
      "Should set the requested permissions"
    )
    XCTAssertEqual(configuration?.tracking, tracking, "Should set the tracking preference")
    XCTAssertEqual(configuration?.nonce, nonce, "Should set the nonce")
    XCTAssertEqual(configuration?.messengerPageId, messengerPageId, "Should set the messenger page ID")
    XCTAssertEqual(configuration?.authType, authType, "Should set the auth type")
    XCTAssertEqual(configuration?.appSwitch, appSwitch, "Should set the app switch behavior")
    XCTAssertEqual(configuration?.codeVerifier.value, codeVerifier.value, "Should set the code verifier")
  }

  func testCreatingWithPermissionsTrackingMessengerPageIdAuthTypeAndAppSwitch() {
    let permissions = ["email"]
    let messengerPageId = "12345"
    let authType = LoginAuthType.rerequest
    let appSwitch = AppSwitch.disabled

    let configuration = LoginConfiguration(
      permissions: permissions,
      tracking: .enabled,
      messengerPageId: messengerPageId,
      authType: authType,
      appSwitch: appSwitch
    )

    XCTAssertEqual(
      configuration?.requestedPermissions,
      FBPermission.permissions(fromRawPermissions: Set(permissions)),
      "Should create a configuration with the provided permissions"
    )
    XCTAssertEqual(
      configuration?.tracking,
      .enabled,
      "Should create a configuration with the provided tracking preference"
    )
    XCTAssertEqual(
      configuration?.messengerPageId,
      messengerPageId,
      "Should create a configuration with the provided messenger page ID"
    )
    XCTAssertEqual(
      configuration?.authType,
      authType,
      "Should create a configuration with the provided auth type"
    )
    XCTAssertEqual(
      configuration?.appSwitch,
      appSwitch,
      "Should create a configuration with the provided app switch behavior"
    )
  }

  func testAppSwitchDefaultsToEnabledWhenNotSpecified() {
    let configurations = [
      LoginConfiguration(),
      LoginConfiguration(tracking: .enabled),
      LoginConfiguration(permissions: ["email"], tracking: .enabled),
      LoginConfiguration(
        permissions: ["email"],
        tracking: .enabled,
        messengerPageId: "123",
        authType: .rerequest
      ),
    ]

    configurations.forEach { configuration in
      XCTAssertEqual(
        configuration?.appSwitch,
        .enabled,
        "App switch should default to enabled when not explicitly specified (opt-out model)"
      )
    }
  }

  func testAppSwitchWithLimitedTracking() {
    let configuration = LoginConfiguration(
      tracking: .limited,
      appSwitch: .disabled
    )

    XCTAssertEqual(
      configuration?.tracking,
      .limited,
      "Should create a configuration with limited tracking"
    )
    XCTAssertEqual(
      configuration?.appSwitch,
      .disabled,
      "Should create a configuration with disabled app switch even with limited tracking"
    )
  }

  func testCreatingWithPermissionsTrackingNonceAndAppSwitch() {
    let permissions = ["email", "public_profile"]
    let tracking = LoginTracking.enabled
    let nonce = "test_nonce_12345"
    let appSwitch = AppSwitch.disabled

    let configuration = LoginConfiguration(
      permissions: permissions,
      tracking: tracking,
      nonce: nonce,
      appSwitch: appSwitch
    )

    XCTAssertNotNil(configuration, "Should create a configuration with permissions, tracking, nonce, and appSwitch")
    XCTAssertEqual(
      configuration?.requestedPermissions,
      FBPermission.permissions(fromRawPermissions: Set(permissions)),
      "Should set the requested permissions"
    )
    XCTAssertEqual(configuration?.tracking, tracking, "Should set the tracking preference")
    XCTAssertEqual(configuration?.nonce, nonce, "Should set the nonce")
    XCTAssertEqual(configuration?.appSwitch, appSwitch, "Should set the app switch behavior")
    XCTAssertEqual(
      configuration?.authType,
      .rerequest,
      "Auth type should default to rerequest when not specified"
    )
  }

  func testCreatingWithPermissionsTrackingNonceMessengerPageIdAndAppSwitch() {
    let permissions = ["email"]
    let tracking = LoginTracking.limited
    let nonce = "nonce_abc123"
    let messengerPageId = "messenger_page_456"
    let appSwitch = AppSwitch.disabled

    let configuration = LoginConfiguration(
      permissions: permissions,
      tracking: tracking,
      nonce: nonce,
      messengerPageId: messengerPageId,
      appSwitch: appSwitch
    )

    XCTAssertNotNil(
      configuration,
      "Should create a configuration with permissions, tracking, nonce, messengerPageId, and appSwitch"
    )
    XCTAssertEqual(
      configuration?.requestedPermissions,
      FBPermission.permissions(fromRawPermissions: Set(permissions)),
      "Should set the requested permissions"
    )
    XCTAssertEqual(configuration?.tracking, tracking, "Should set the tracking preference")
    XCTAssertEqual(configuration?.nonce, nonce, "Should set the nonce")
    XCTAssertEqual(configuration?.messengerPageId, messengerPageId, "Should set the messenger page ID")
    XCTAssertEqual(configuration?.appSwitch, appSwitch, "Should set the app switch behavior")
    XCTAssertEqual(
      configuration?.authType,
      .rerequest,
      "Auth type should default to rerequest when not specified"
    )
  }

  func testCreatingWithPermissionsTrackingMessengerPageIdAndAppSwitch() {
    let permissions = ["email", "user_friends"]
    let tracking = LoginTracking.enabled
    let messengerPageId = "page_789"
    let appSwitch = AppSwitch.disabled

    let configuration = LoginConfiguration(
      permissions: permissions,
      tracking: tracking,
      messengerPageId: messengerPageId,
      appSwitch: appSwitch
    )

    XCTAssertNotNil(
      configuration,
      "Should create a configuration with permissions, tracking, messengerPageId, and appSwitch"
    )
    XCTAssertEqual(
      configuration?.requestedPermissions,
      FBPermission.permissions(fromRawPermissions: Set(permissions)),
      "Should set the requested permissions"
    )
    XCTAssertEqual(configuration?.tracking, tracking, "Should set the tracking preference")
    XCTAssertNotNil(configuration?.nonce, "Nonce should be auto-generated when not specified")
    XCTAssertEqual(configuration?.messengerPageId, messengerPageId, "Should set the messenger page ID")
    XCTAssertEqual(configuration?.appSwitch, appSwitch, "Should set the app switch behavior")
    XCTAssertEqual(
      configuration?.authType,
      .rerequest,
      "Auth type should default to rerequest when not specified"
    )
  }

  func testCreatingWithPermissionsTrackingAndAppSwitch() {
    let permissions = ["email"]
    let tracking = LoginTracking.limited
    let appSwitch = AppSwitch.disabled

    let configuration = LoginConfiguration(
      permissions: permissions,
      tracking: tracking,
      appSwitch: appSwitch
    )

    XCTAssertNotNil(configuration, "Should create a configuration with permissions, tracking, and appSwitch")
    XCTAssertEqual(
      configuration?.requestedPermissions,
      FBPermission.permissions(fromRawPermissions: Set(permissions)),
      "Should set the requested permissions"
    )
    XCTAssertEqual(configuration?.tracking, tracking, "Should set the tracking preference")
    XCTAssertNotNil(configuration?.nonce, "Nonce should be auto-generated when not specified")
    XCTAssertNil(configuration?.messengerPageId, "Messenger page ID should be nil when not specified")
    XCTAssertEqual(configuration?.appSwitch, appSwitch, "Should set the app switch behavior")
    XCTAssertEqual(
      configuration?.authType,
      .rerequest,
      "Auth type should default to rerequest when not specified"
    )
  }
}

// swiftformat:disable extensionaccesscontrol

// MARK: - Assumptions

fileprivate extension String {
  static let createsConfigWithAuthType = "Creates a configuration with the provided auth_type"
  static let createsConfigWithMessengerID = "Creates a configuration with the provided Messenger Page Id"
}
