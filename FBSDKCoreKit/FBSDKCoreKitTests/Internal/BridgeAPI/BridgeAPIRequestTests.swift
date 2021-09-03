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

import UIKit
import XCTest

class BridgeAPIRequestTests: XCTestCase {

  override func tearDown() {
    BridgeAPIRequest.resetClassDependencies()
    super.tearDown()
  }

  func testClassDependencies() {
    _ = BridgeAPIRequest(
      protocolType: .native,
      scheme: "http",
      methodName: nil,
      methodVersion: nil,
      parameters: nil,
      userInfo: nil
    )

    let testInternalURLOpener = {
      XCTAssertTrue(
        BridgeAPIRequest.internalURLOpener === UIApplication.shared,
        "BridgeAPIRequest should use the shared application for its default internal URL opener dependency"
      )
    }

    #if BUCK
    testInternalURLOpener()
    #else
    XCTExpectFailure(
      "The following test should fail since the tests do not have a valid application singleton",
      failingBlock: testInternalURLOpener
    )
    #endif

    XCTAssertTrue(
      BridgeAPIRequest.internalUtility === InternalUtility.shared,
      "BridgeAPIRequest should use the shared utility for its default internal utility dependency"
    )
    XCTAssertTrue(
      BridgeAPIRequest.settings === Settings.shared,
      "BridgeAPIRequest should use the shared settings for its default settings dependency"
    )
  }

  func testDefaultProtocolConformance() {
    XCTAssertTrue(
      (BridgeAPIRequest.self as Any) is BridgeAPIRequestProtocol.Type,
      "BridgeAPIRequest should conform to the expected protocol"
    )
  }
}
