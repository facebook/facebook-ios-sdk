/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class ShareDialogConfigurationTests: XCTestCase {

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
