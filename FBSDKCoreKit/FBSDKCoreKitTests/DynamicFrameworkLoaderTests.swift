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

import AuthenticationServices
import CoreTelephony
import FBSDKCoreKit
import SafariServices
import Security
import Social
import XCTest

@available(iOS 12.0, *)
class DynamicFrameworkLoaderTests: XCTestCase {

  #if BUCK
  let expectedOSStatus = errSecNotAvailable
  #else
  let expectedOSStatus = errSecMissingEntitlement
  #endif

  func testLoadingSecureConstants() { // swiftlint:disable:this function_body_length
    XCTAssertTrue(
      CFEqual(
        DynamicFrameworkLoader.loadkSecClass().takeRetainedValue(),
        kSecClass
      ),
      "Should dynamically load the constant kSecClass"
    )
    XCTAssertTrue(
      CFEqual(
        DynamicFrameworkLoader.loadkSecReturnData().takeRetainedValue(),
        kSecReturnData
      ),
      "Should dynamically load the constant kSecReturnData"
    )
    XCTAssertTrue(
      CFEqual(
        DynamicFrameworkLoader.loadkSecAttrAccessible().takeRetainedValue(),
        kSecAttrAccessible
      ),
      "Should dynamically load the constant kSecAttrAccessible"
    )
    XCTAssertTrue(
      CFEqual(
        DynamicFrameworkLoader.loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly().takeRetainedValue(),
        kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
      ),
      "Should dynamically load the constant kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly"
    )
    XCTAssertTrue(
      CFEqual(
        DynamicFrameworkLoader.loadkSecAttrAccount().takeRetainedValue(),
        kSecAttrAccount
      ),
      "Should dynamically load the constant kSecAttrAccount"
    )
    XCTAssertTrue(
      CFEqual(
        DynamicFrameworkLoader.loadkSecAttrService().takeRetainedValue(),
        kSecAttrService
      ),
      "Should dynamically load the constant kSecAttrService"
    )
    XCTAssertTrue(
      CFEqual(
        DynamicFrameworkLoader.loadkSecValueData().takeRetainedValue(),
        kSecValueData
      ),
      "Should dynamically load the constant kSecValueData"
    )
    XCTAssertTrue(
      CFEqual(
        DynamicFrameworkLoader.loadkSecClassGenericPassword().takeRetainedValue(),
        kSecClassGenericPassword
      ),
      "Should dynamically load the constant kSecClassGenericPassword"
    )
    XCTAssertTrue(
      CFEqual(
        DynamicFrameworkLoader.loadkSecAttrAccessGroup().takeRetainedValue(),
        kSecAttrAccessGroup
      ),
      "Should dynamically load the constant kSecAttrAccessGroup"
    )
    XCTAssertTrue(
      CFEqual(
        DynamicFrameworkLoader.loadkSecMatchLimitOne().takeRetainedValue(),
        kSecMatchLimitOne
      ),
      "Should dynamically load the constant kSecMatchLimitOne"
    )
    XCTAssertTrue(
      CFEqual(
        DynamicFrameworkLoader.loadkSecMatchLimit().takeRetainedValue(),
        kSecMatchLimit
      ),
      "Should dynamically load the constant kSecMatchLimit"
    )
    XCTAssertTrue(
      CFEqual(
        DynamicFrameworkLoader.loadkSecReturnData().takeRetainedValue(),
        kSecReturnData
      ),
      "Should dynamically load the constant kSecReturnData"
    )
    XCTAssertTrue(
      CFEqual(
        DynamicFrameworkLoader.loadkSecClass().takeRetainedValue(),
        kSecClass
      ),
      "Should dynamically load the constant kSecClass"
    )
  }

  func testSecRandomRef() {
    var bytes = [Int8](repeating: 0, count: 10)
    var bytes2 = [Int8](repeating: 0, count: 10)

    let status = fbsdkdfl_SecRandomCopyBytes(DynamicFrameworkLoader.loadkSecRandomDefault(), bytes.count, &bytes)
    let status2 = fbsdkdfl_SecRandomCopyBytes(DynamicFrameworkLoader.loadkSecRandomDefault(), bytes2.count, &bytes2)

    XCTAssertEqual(status, errSecSuccess, "Random byte generation should succeed")
    XCTAssertEqual(status2, errSecSuccess, "Random byte generation should succeed")

    XCTAssertNotEqual(bytes, bytes2)
  }

  func testSecItemUpdate() {
    let query = [
      kSecClass as String: kSecClassGenericPassword as String,
      kSecAttrService as String: name,
      kSecAttrAccount as String: "key"
    ]
    let attributesToUpdate = [
      kSecValueData as String: "foo".data(using: .utf8)
    ]
    let status = fbsdkdfl_SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

    guard status == expectedOSStatus else {
      return XCTFail("Failed to try and set secure data")
    }
  }

  func testSecItemAdd() {
    let query = [
      kSecClass as String: kSecClassGenericPassword as String,
      kSecAttrService as String: name,
      kSecAttrAccount as String: "key",
      kSecValueData as String: "foo".data(using: .utf8) as Any
    ]
    let status = fbsdkdfl_SecItemAdd(query as CFDictionary, nil)

    guard status == expectedOSStatus else {
      return XCTFail("Failed to try and set secure data")
    }
  }

  func testSecItemCopyMatching() {
    let query: [String: Any?] = [
      kSecClass as String: kSecClassGenericPassword as String,
      kSecAttrService as String: name,
      kSecAttrAccount as String: "key",
      kSecReturnData as String: kCFBooleanTrue,
      kSecReturnAttributes as String: kCFBooleanTrue,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    var queryResult: AnyObject?
    let status = withUnsafeMutablePointer(to: &queryResult) {
      fbsdkdfl_SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
    }

    guard status == expectedOSStatus else {
      return XCTFail("Failed to try and fetch secure data")
    }
  }

  func testSecItemDelete() {
    let query: [String: Any?] = [
      kSecClass as String: kSecClassGenericPassword as String,
      kSecAttrService as String: name,
      kSecAttrAccount as String: "key"
    ]
    let status = fbsdkdfl_SecItemDelete(query as CFDictionary)

    guard status == expectedOSStatus else {
      return XCTFail("Failed to try and delete secure data")
    }
  }

  func testSLServiceTypeFacebook() {
    XCTAssertEqual(
      fbsdkdfl_SLServiceTypeFacebook(),
      "com.apple.social.facebook",
      "Should dynamically load the constant for the facebook service type"
    )
  }

  func testSLComposeViewControllerClass() {
    XCTAssertTrue(
      fbsdkdfl_SLComposeViewControllerClass() is SLComposeViewController.Type,
      "Should dynamically load the SLComposeViewController class"
    )
  }

  func testCATransactionClass() {
    XCTAssertTrue(
      fbsdkdfl_CATransactionClass() is CATransaction.Type,
      "Should dynamically load the CATransaction class"
    )
  }

  func testCATransform3DMakeScale() {
    let transform = fbsdkdfl_CATransform3DMakeScale(10, 10, 10)
    let transform2 = CATransform3DMakeScale(10, 10, 10)

    XCTAssertTrue(
      CATransform3DEqualToTransform(transform, transform2)
    )
  }

  func testCATransform3DMakeTranslation() {
    let transform = fbsdkdfl_CATransform3DMakeTranslation(10, 10, 10)
    let transform2 = CATransform3DMakeTranslation(10, 10, 10)

    XCTAssertTrue(
      CATransform3DEqualToTransform(transform, transform2)
    )
  }

  func testCATransform3DConcat() {
    let scale = CATransform3DMakeScale(10, 10, 10)
    let transform = fbsdkdfl_CATransform3DConcat(scale, scale)
    let transform2 = CATransform3DConcat(scale, scale)

    XCTAssertTrue(
      CATransform3DEqualToTransform(transform, transform2)
    )
  }

  func testASIdentifierManagerClass() {
    XCTAssertTrue(
      fbsdkdfl_ASIdentifierManagerClass() is ASIdentifierManager.Type,
      "Should dynamically load the ASIdentifierManager class"
    )
  }

  func testSFSafariViewControllerClass() {
    XCTAssertTrue(
      fbsdkdfl_SFSafariViewControllerClass() is SFSafariViewController.Type,
      "Should dynamically load the SFSafariViewController class"
    )
  }

  func testSFAuthenticationSessionClass() {
    XCTAssertTrue(
      fbsdkdfl_SFAuthenticationSessionClass() is SFAuthenticationSession.Type,
      "Should dynamically load the SFAuthenticationSession class"
    )
  }

  func testASWebAuthenticationSessionClass() {
    XCTAssertTrue(
      fbsdkdfl_ASWebAuthenticationSessionClass() is ASWebAuthenticationSession.Type,
      "Should dynamically load the ASWebAuthenticationSession class"
    )
  }

  func testCTTelephonyNetworkInfoClass() {
    XCTAssertTrue(
      fbsdkdfl_CTTelephonyNetworkInfoClass() is CTTelephonyNetworkInfo.Type,
      "Should dynamically load the CTTelephonyNetworkInfo class"
    )
  }
}
