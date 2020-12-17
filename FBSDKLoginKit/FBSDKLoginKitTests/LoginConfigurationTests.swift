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
      config?.requestedPermissions,
      Set(permissions.map { $0.name }),
      "Should create a configuration with the provided tracking preference"
    )
  }

  func testCreatingWithPermissionsForLimitedTracking() {
    let allowedPermissions = Set([Permission.email])
    let disallowedPermissions = Set([Permission.userBirthday, .userPosts])

    var configuration = LoginConfiguration(
      permissions: disallowedPermissions,
      tracking: .limited
    )
    XCTAssertNil(
      configuration,
      "Should not create a configuration with permissions that are disallowed based on the tracking preference" // swiftlint:disable:this line_length
    )

    configuration = LoginConfiguration(
      permissions: allowedPermissions,
      tracking: .limited
    )
    XCTAssertNotNil(
      configuration,
      "Should create a configuration with permissions that are allowed based on the tracking preference" // swiftlint:disable:this line_length
    )
  }
}
