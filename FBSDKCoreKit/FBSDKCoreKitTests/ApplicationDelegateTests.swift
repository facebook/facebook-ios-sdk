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

class ApplicationDelegateTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional weak_delegate
  var center: TestNotificationCenter!
  var delegate: ApplicationDelegate!
  // swiftlint:enable implicitly_unwrapped_optional weak_delegate

  override func setUp() {
    super.setUp()

    ApplicationDelegate.reset()
    center = TestNotificationCenter()
    delegate = ApplicationDelegate(
      notificationObserver: center,
      tokenWallet: TestAccessTokenWallet.self,
      settings: TestSettings.self
    )
  }

  func testDefaultNotificationCenter() {
    XCTAssertEqual(
      ApplicationDelegate.shared.notificationObserver as? NotificationCenter,
      NotificationCenter.default,
      "Should use the default system notification center"
    )
  }

  func testCreatingAndDestroyingWithNotificationCenter() {
    XCTAssertTrue(
      delegate.notificationObserver is TestNotificationCenter,
      "Should be able to create with a custom notification center"
    )
  }

  func testDefaultAccessTokenSetter() {
    XCTAssertTrue(
      ApplicationDelegate.shared.tokenWallet is AccessToken.Type,
      "Should use the expected default access token setter"
    )
  }

  func testCreatingWithAccessTokenSetter() {
    XCTAssertTrue(
      delegate.tokenWallet is TestAccessTokenWallet.Type,
      "Should be able to create with a custom access token setter"
    )
  }

  // TODO: Re-enable once we can ensure initializing from tests wont result in network calls
  // being made by dependencies.
  func _testInitializingSdkObservesSystemNotifications() { // swiftlint:disable:this identifier_name
    ApplicationDelegate.initializeSDK(with: delegate, launchOptions: [:])

    XCTAssertTrue(
      center.capturedAddObserverInvocations.contains(
        TestNotificationCenter.ObserverEvidence(
          observer: delegate as Any,
          name: UIApplication.didEnterBackgroundNotification,
          selector: #selector(ApplicationDelegate.applicationDidEnterBackground(_:)),
          object: nil
        )
      ),
      "Should start observing application backgrounding upon initializtion"
    )
    XCTAssertTrue(
      center.capturedAddObserverInvocations.contains(
        TestNotificationCenter.ObserverEvidence(
          observer: delegate as Any,
          name: UIApplication.didBecomeActiveNotification,
          selector: #selector(ApplicationDelegate.applicationDidBecomeActive(_:)),
          object: nil
        )
      ),
      "Should start observing application foregrounding upon initializtion"
    )
    XCTAssertTrue(
      center.capturedAddObserverInvocations.contains(
        TestNotificationCenter.ObserverEvidence(
          observer: delegate as Any,
          name: UIApplication.willResignActiveNotification,
          selector: #selector(ApplicationDelegate.applicationWillResignActive(_:)),
          object: nil
        )
      ),
      "Should start observing application resignation upon initializtion"
    )
  }
}
