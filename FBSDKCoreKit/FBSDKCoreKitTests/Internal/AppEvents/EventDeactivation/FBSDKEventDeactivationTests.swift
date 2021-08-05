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

class FBSDKEventDeactivationTests: XCTestCase {

  enum Keys {
    static let ui = "_ui" // swiftlint:disable:this identifier_name
    static let logTime = "_logTime"
    static let sessionID = "_session_id"
    static let launchSource = "fb_mobile_launch_source"
    static let deprecated = "deprecated_3"
  }

  let rawConfiguration = [
    "restrictiveParams": [
      "fb_mobile_catalog_update": [
        "restrictive_param": ["first_name": "6"]
      ],
      "manual_initiated_checkout": [
        "deprecated_param": ["deprecated_3"]
      ]
    ]
  ]
  lazy var serverConfiguration = ServerConfigurationFixtures.config(withDictionary: rawConfiguration)
  lazy var provider = TestServerConfigurationProvider(configuration: serverConfiguration)
  lazy var eventDeactivationManager = EventDeactivationManager(
    serverConfigurationProvider: provider
  )

  func testProcessParameters() {
    eventDeactivationManager.enable()

    let parameters: [String: Any] = [
      Keys.ui: "UITabBarController",
      Keys.logTime: 1_576_109_848,
      Keys.sessionID: "30AF582C-0225-40A4-B3EE-2A571AB926F3",
      Keys.launchSource: "Unclassified",
      Keys.deprecated: "test",
    ]

    guard let result = eventDeactivationManager.processParameters(
      parameters,
      eventName: "manual_initiated_checkout"
    ) else {
      XCTFail("Result must not be nil")
      return
    }

    XCTAssertNil(result[Keys.deprecated])
    XCTAssertNotNil(result[Keys.ui])
    XCTAssertNotNil(result[Keys.logTime])
    XCTAssertNotNil(result[Keys.sessionID])
    XCTAssertNotNil(result[Keys.launchSource])
  }
}
