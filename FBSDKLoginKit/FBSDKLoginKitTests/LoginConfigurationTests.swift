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
}

// MARK: - Assumptions

fileprivate extension String {
  static let createsConfigWithAuthType = "Creates a configuration with the provided auth_type"
  static let createsConfigWithMessengerID = "Creates a configuration with the provided Messenger Page Id"
}
