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
    guard let config = LoginConfiguration() else {
      return XCTFail("Should be able to create a config with default arguments")
    }

    XCTAssertEqual(
      config.requestedPermissions,
      [],
      "A config should be created with default requested permissions"
    )
    XCTAssertEqual(
      config.tracking,
      .enabled,
      "Tracking should default to enabled when unspecified"
    )
    XCTAssertNotNil(
      config.nonce,
      "A config should be created with a default nonce"
    )
    XCTAssertNil(
      config.messengerPageId,
      "Messenger Page Id should default to nil when unspecified"
    )
    XCTAssertEqual(
      config.authType,
      .rerequest,
      "Auth Type should default to rerequest when unspecified"
    )
    XCTAssertNotNil(
      config.codeVerifier,
      "A config should be created with a default code verifier"
    )
  }

  func testCreatingWithNonceString() {
    let nonce = "12345"
    let config = LoginConfiguration(nonce: nonce)
    XCTAssertEqual(
      config?.nonce,
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
      let config = LoginConfiguration(tracking: preference)
      XCTAssertEqual(
        config?.tracking,
        preference,
        "Should create a configuration with the provided tracking preference"
      )
    }
  }

  func testCreatingWithRequestedPermissions() {
    let permissions = Set([Permission.email, .userLikes])
    let config = LoginConfiguration(permissions: permissions)

    XCTAssertEqual(
      Set((config?.requestedPermissions.map { $0.value })!), // swiftlint:disable:this force_unwrapping
      Set(permissions.map { $0.name }),
      "Should create a configuration with the provided tracking preference"
    )
  }

  func testCreatingWithMessengerPageId() {
    let messengerPageId = "12345"
    let config = LoginConfiguration(messengerPageId: messengerPageId)
    XCTAssertEqual(
      config?.messengerPageId,
      messengerPageId,
      .createsConfigWithMessengerID
    )
  }

  func testCreatingWithPermissionsTrackingAndMessengerPageId() {
    let messengerPageId = "12345"
    let permissions = ["email"]

    let config = LoginConfiguration(
      permissions: permissions,
      tracking: .enabled,
      messengerPageId: messengerPageId
    )

    XCTAssertEqual(
      config?.requestedPermissions,
      FBPermission.permissions(fromRawPermissions: Set(permissions)),
      .createsConfigWithMessengerID
    )

    XCTAssertEqual(
      config?.tracking,
      LoginTracking.enabled,
      .createsConfigWithMessengerID
    )

    XCTAssertEqual(
      config?.messengerPageId,
      messengerPageId,
      .createsConfigWithMessengerID
    )
  }

  func testCreatingWithRerequestAuthType() {
    let authType = LoginAuthType.rerequest
    let config = LoginConfiguration(authType: authType)
    XCTAssertEqual(
      config?.authType,
      authType,
      .createsConfigWithAuthType
    )
  }

  func testCreatingWithPermissionsTrackingAndAuthType() {
    let authType = LoginAuthType.rerequest
    let permissions = ["email"]
    let messengerPageId = "12345"

    let config = LoginConfiguration(
      permissions: permissions,
      tracking: .enabled,
      messengerPageId: messengerPageId,
      authType: authType
    )

    XCTAssertEqual(
      config?.requestedPermissions,
      FBPermission.permissions(fromRawPermissions: Set(permissions)),
      .createsConfigWithAuthType
    )

    XCTAssertEqual(
      config?.tracking,
      LoginTracking.enabled,
      .createsConfigWithAuthType
    )

    XCTAssertEqual(
      config?.messengerPageId,
      messengerPageId,
      .createsConfigWithAuthType
    )

    XCTAssertEqual(
      config?.authType,
      authType,
      .createsConfigWithAuthType
    )
  }

  func testCreatingWithReauthorizeAuthType() {
    let authType = LoginAuthType.reauthorize
    let config = LoginConfiguration(authType: authType)
    XCTAssertEqual(
      config?.authType,
      authType,
      "Should create a configuration with the provided auth_type"
    )
  }

  func testCreatingWithNilAuthType() {
    let config = LoginConfiguration(authType: nil)
    XCTAssertNil(
      config?.authType,
      "Should treat a nil auth type as nil"
    )
  }

  func testAuthTypeForStringWithInvalidAuthType() {
    XCTAssertNil(LoginConfiguration.authType(for: "foo"), "Should return nil for invalid auth types")
  }

  func testAuthTypeForStringWithValidAuthType() {
    XCTAssertEqual(
      LoginConfiguration.authType(for: "rerequest"),
      .rerequest,
      "Should return corresponding auth type when valid raw auth type is given"
    )
  }

  func testCreatingWithCodeVerifier() {
    let codeVerifier = CodeVerifier()
    let config = LoginConfiguration(permissions: [], codeVerifier: codeVerifier)
    XCTAssertEqual(
      config?.codeVerifier.value,
      codeVerifier.value,
      "Should create a configuration with the provided code verifier"
    )
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let createsConfigWithAuthType = "Creates a configuration with the provided auth_type"
  static let createsConfigWithMessengerID = "Creates a configuration with the provided Messenger Page Id"
}
