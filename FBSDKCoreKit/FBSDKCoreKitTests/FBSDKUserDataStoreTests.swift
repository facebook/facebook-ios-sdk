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

class FBSDKUserDataStoreTests: XCTestCase {

  let store = UserDataStore()
  let email = "apptest@fb.com"

  override func setUp() {
    super.setUp()

    store.clearUserData()
  }

  override func tearDown() {
    super.tearDown()

    store.clearUserData()
  }

  func testSettingUserDataByType() throws {
    let hashedEmail = try XCTUnwrap(
      BasicUtility.sha256Hash(NSString(utf8String: email))
    )

    store.setUserData(email, forType: .email)
    let retrieved = try XCTUnwrap(
      store.getUserData(),
      "Should be able to retrieve stored user data"
    )

    XCTAssertTrue(
      retrieved.contains("em"),
      "Should store the data under the expected key"
    )
    XCTAssertTrue(
      retrieved.contains(hashedEmail),
      "Should hash the data before storing it"
    )
  }

  func testClearingUserDataByType() throws {
    store.setUserData(email, forType: .email)
    store.setUserData(name, forType: .firstName)
    store.clearUserData(forType: .email)

    let retrieved = try XCTUnwrap(
      store.getUserData(),
      "Should be able to retrieve stored user data"
    )

    // User data is stored as a string representation of a dictionary.
    // example: `{"key": "hashed value"}`
    XCTAssertFalse(
      retrieved.contains("em"),
      "Should clear the provided type of user data"
    )
    XCTAssertTrue(
      retrieved.contains("fn"),
      "Should not clear unspecified user data"
    )
  }
}
