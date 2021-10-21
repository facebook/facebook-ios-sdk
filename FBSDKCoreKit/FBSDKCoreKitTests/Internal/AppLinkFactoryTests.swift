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
import TestTools
import XCTest

class AppLinkFactoryTests: XCTestCase {

  let sourceURL = SampleURLs.valid(path: "source")
  let webURL = SampleURLs.valid(path: "webURL")
  let target = TestAppLinkTarget(url: nil, appStoreId: nil, appName: "foo")
  let isBackToReferrer = Bool.random()

  func testCreatingAppLink() {
    let factory = AppLinkFactory()
    guard let appLink = factory.createAppLink(
      sourceURL: sourceURL,
      targets: [target],
      webURL: webURL,
      isBackToReferrer: isBackToReferrer
    ) as? AppLink
    else {
      return XCTFail("Should create the app links of the expected concrete type")
    }

    XCTAssertEqual(
      appLink.sourceURL,
      sourceURL,
      "Should use the provided source URL to create the app link"
    )
    XCTAssertEqual(
      appLink.webURL,
      webURL,
      "Should use the provided web URL to create the app link"
    )
    XCTAssertTrue(
      appLink.targets[0] as? TestAppLinkTarget === target,
      "Should use the provided targets to create the app link"
    )
    XCTAssertEqual(
      appLink.isBackToReferrer,
      isBackToReferrer,
      "Should use the provided is back to referrer flag to create the app link"
    )
  }
}
