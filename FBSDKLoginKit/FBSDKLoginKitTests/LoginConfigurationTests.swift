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

#if BUCK
import FacebookCore
#endif

import XCTest

class LoginConfigurationTests: XCTestCase {

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
      .limited
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
      "Should create a configuration with the provided Messenger Page Id"
    )
  }

  func testCreatingWithRerequestAuthType() {
    let authType = LoginAuthType.rerequest
    let config = LoginConfiguration(authType: authType)
    XCTAssertEqual(
      config?.authType,
      authType,
      "Should create a configuration with the provided auth_type"
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
    XCTAssertEqual(
      config?.authType,
      nil,
      "Should treat a nil auth type as nil"
    )
  }

  func testAuthTypeForStringWithInvalidAuthType() {
    XCTAssertNil(LoginConfiguration.authType(for: "foo"),
                 "Should return nil for invalid auth types")
  }

  func testAuthTypeForStringWithValidAuthType() {
    XCTAssertEqual(
      LoginConfiguration.authType(for: "rerequest"),
      .rerequest,
      "Should return corresponding auth type when valid raw auth type is given"
    )
  }
}
