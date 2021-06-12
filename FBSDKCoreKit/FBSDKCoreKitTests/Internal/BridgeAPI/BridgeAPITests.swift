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

class BridgeAPIRequestTests: XCTestCase {

  let processInfo = TestProcessInfo()
  let logger = TestLogger()
  let urlOpener = TestURLOpener()
  let responseFactory = TestBridgeApiResponseFactory()
  let frameworkLoader = TestDylibResolver()
  let appURLSchemeProvider = TestAppURLSchemeProvider()

  func testDefaults() {
    XCTAssertTrue(
      BridgeAPI.shared.processInfo is ProcessInfo,
      "The shared bridge API should use the system provided process info by default"
    )
    XCTAssertTrue(
      BridgeAPI.shared.logger is Logger,
      "The shared bridge API should use the expected logger type by default"
    )
    XCTAssertEqual(
      BridgeAPI.shared.urlOpener as? UIApplication,
      UIApplication.shared,
      "Should use the expected concrete url opener by default"
    )
    XCTAssertTrue(
      BridgeAPI.shared.bridgeAPIResponseFactory is BridgeAPIResponseFactory,
      "Should use and instance of the expected concrete response factory type by default"
    )
    XCTAssertEqual(
      BridgeAPI.shared.frameworkLoader as? DynamicFrameworkLoader,
      DynamicFrameworkLoader.shared(),
      "Should use the expected instance of dynamic framework loader"
    )
    XCTAssertEqual(
      BridgeAPI.shared.appURLSchemeProvider as? InternalUtility,
      InternalUtility.shared,
      "Should use the expected instance of internal utility"
    )
  }

  func testConfiguringWithDependencies() {
    let api = BridgeAPI(
      processInfo: processInfo,
      logger: logger,
      urlOpener: urlOpener,
      bridgeAPIResponseFactory: responseFactory,
      frameworkLoader: frameworkLoader,
      appURLSchemeProvider: appURLSchemeProvider
    )

    XCTAssertEqual(
      api.processInfo as? TestProcessInfo,
      processInfo,
      "Should be able to create a bridge api with a specific process info"
    )
    XCTAssertEqual(
      api.logger as? TestLogger,
      logger,
      "Should be able to create a bridge api with a specific logger"
    )
    XCTAssertEqual(
      api.urlOpener as? TestURLOpener,
      urlOpener,
      "Should be able to create a bridge api with a specific url opener"
    )
    XCTAssertEqual(
      api.bridgeAPIResponseFactory as? TestBridgeApiResponseFactory,
      responseFactory,
      "Should be able to create a bridge api with a specific response factory"
    )
    XCTAssertEqual(
      api.frameworkLoader as? TestDylibResolver,
      frameworkLoader,
      "Should be able to create a bridge api with a specific framework loader"
    )
  }
}
