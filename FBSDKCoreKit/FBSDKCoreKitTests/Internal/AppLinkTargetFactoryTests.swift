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

class AppLinkTargetFactoryTests: XCTestCase {

  let url = SampleURLs.valid
  let appStoreId = "123"

  func testCreatingAppLinkTarget() throws {
    let factory = AppLinkTargetFactory()
    let target = try XCTUnwrap(
      factory.createAppLinkTarget(
        url: url,
        appStoreId: appStoreId,
        appName: name
      ) as? AppLinkTarget,
      "Should create an app link target of the expected concrete type"
    )

    XCTAssertEqual(
      target.url,
      url,
      "Should use the provided url to create the app link target"
    )
    XCTAssertEqual(
      target.appStoreId,
      appStoreId,
      "Should use the provided app store identifier to create the app link target"
    )
    XCTAssertEqual(
      target.appName,
      name,
      "Should use the provided name to create the app link target"
    )
  }
}
