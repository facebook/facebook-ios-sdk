/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class ShareDialogConfigurationTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var serverConfiguration: TestServerConfiguration!
  var provider: TestServerConfigurationProvider!
  var configuration: ShareDialogConfiguration!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    serverConfiguration = TestServerConfiguration()
    provider = TestServerConfigurationProvider(configuration: serverConfiguration)
    configuration = ShareDialogConfiguration()

    configuration.setDependencies(
      .init(serverConfigurationProvider: provider)
    )
  }

  override func tearDown() {
    configuration.resetDependencies()

    serverConfiguration = nil
    provider = nil
    configuration = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    configuration.resetDependencies()
    let dependencies = try configuration.getDependencies()

    XCTAssertTrue(
      dependencies.serverConfigurationProvider is _ServerConfigurationManager,
      """
      The ShareDialogConfiguration type uses _ServerConfigurationManager as
      its ServerConfigurationProvider dependency by default
      """
    )
  }

  func testCreatingWithCustomDependencies() {
    XCTAssertEqual(
      configuration.serverConfigurationProvider as? TestServerConfigurationProvider,
      provider,
      "Should be able to configure with a custom server configuration provider"
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
    _ = configuration.shouldUseNativeDialog(forDialogName: name)
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
    _ = configuration.shouldUseSafariViewController(forDialogName: name)
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
