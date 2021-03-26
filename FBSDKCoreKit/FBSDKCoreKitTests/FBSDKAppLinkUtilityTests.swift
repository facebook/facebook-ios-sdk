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

class FBSDKAppLinkUtilityTests: FBSDKTestCase {

  let requestFactory = TestGraphRequestFactory()
  var bundle = TestBundle()

  override func setUp() {
    super.setUp()

    TestAppEventsConfigurationProvider.stubbedConfiguration = SampleAppEventsConfigurations.valid
    AppLinkUtility.configure(
      requestProvider: requestFactory,
      infoDictionaryProvider: bundle
    )
  }

  override class func tearDown() {
    super.tearDown()

    // This can be removed once AppLinkUtility injects a manager.
    AppEventsConfigurationManager.reset()
    TestAppEventsConfigurationProvider.reset()
  }

  func testConfiguringWithRequestProvider() {
    XCTAssertTrue(
      AppLinkUtility.requestProvider is TestGraphRequestFactory,
      "Should use the provided request provider type"
    )
  }

  func testConfiguringWithInfoDictionary() {
    XCTAssertTrue(
      AppLinkUtility.infoDictionaryProvider is TestBundle,
      "Should use the provided info dictionary provider type"
    )
  }

  func testWithNoPromoCode() {
    let url = URL(string: "myapp://somelink/?someparam=somevalue")! // swiftlint:disable:this force_unwrapping
    let promoCode = AppLinkUtility.appInvitePromotionCode(from: url)
    XCTAssertNil(promoCode)
  }

  func testWithPromoCode() {
    let url = URL(string: "myapp://somelink/?al_applink_data=%7B%22target_url%22%3Anull%2C%22extras%22%3A%7B%22deeplink_context%22%3A%22%7B%5C%22promo_code%5C%22%3A%5C%22PROMOWORKS%5C%22%7D%22%7D%7D")! // swiftlint:disable:this line_length force_unwrapping
    let promoCode = AppLinkUtility.appInvitePromotionCode(from: url)
    XCTAssertNotNil(promoCode)
    XCTAssertEqual(promoCode, "PROMOWORKS")
  }

  func testIsMatchURLScheme() {
    let bundleDict = [
      "CFBundleURLTypes": [
        [
          "CFBundleURLSchemes": ["fb123"]
        ]
      ]
    ]
    bundle = TestBundle(infoDictionary: bundleDict)

    AppLinkUtility.configure(
      requestProvider: requestFactory,
      infoDictionaryProvider: bundle
    )

    XCTAssertTrue(AppLinkUtility.isMatchURLScheme("fb123"))
    XCTAssertFalse(AppLinkUtility.isMatchURLScheme("not_in_url_schemes"))
  }

  func testRequestProviderAfterGraphRequest() {
    AppEventsConfigurationManager.configure(store: UserDefaultsSpy())

    AppLinkUtility.fetchDeferredAppLink()
    XCTAssertEqual(requestFactory.capturedGraphPath, "(null)/activities")
    XCTAssertEqual(requestFactory.capturedHttpMethod, HTTPMethod(rawValue: "POST"))
  }

}
