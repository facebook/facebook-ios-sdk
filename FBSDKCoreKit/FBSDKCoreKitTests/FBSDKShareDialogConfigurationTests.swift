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

class FBSDKShareDialogConfigurationTests: XCTestCase {

  let serverConfiguration = TestServerConfiguration()
  lazy var provider = TestServerConfigurationProvider(configuration: serverConfiguration)
  lazy var configuration = ShareDialogConfiguration(serverConfigurationProvider: provider)

  func testDefaults() {
    let configuration = ShareDialogConfiguration()

    XCTAssertEqual(
      configuration.serverConfigurationProvider as? ServerConfigurationManager,
      ServerConfigurationManager.shared,
      "Should use the expected default server configuration provider"
    )
  }

  func testCreatingWithCustomDependencies() {
    XCTAssertEqual(
      configuration.serverConfigurationProvider as? TestServerConfigurationProvider,
      provider,
      "Should be able to create with a custom server configuration provider"
    )
  }

  func testDefaultShareMode() {
    serverConfiguration.stubbedDefaultShareMode = name

    XCTAssertEqual(
      configuration.defaultShareMode,
      name,
      "Should delegate retrieving the default share mode to the underlying server configuration"
    )
  }

  func testShouldUseNativeDialog() {
    configuration.shouldUseNativeDialog(forDialogName: name)
    XCTAssertTrue(
      provider.didRetrieveCachedServerConfiguration,
      "Checking if a native dialog should be used should retrieve a server configuration to query"
    )
    XCTAssertEqual(
      serverConfiguration.capturedUseNativeDialogName,
      name,
      "Should delegate to the underlying server configuration"
    )
  }

  func testShouldUseSafariController() {
    configuration.shouldUseSafariViewController(forDialogName: name)
    XCTAssertTrue(
      provider.didRetrieveCachedServerConfiguration,
      "Checking if a native dialog should be used should retrieve a server configuration to query"
    )
    XCTAssertEqual(
      serverConfiguration.capturedUseSafariControllerName,
      name,
      "Should delegate to the underlying server configuration"
    )
  }
}
