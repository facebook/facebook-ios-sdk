/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

class BridgeAPITests: XCTestCase {

  let processInfo = TestProcessInfo()
  let logger = TestLogger(loggingBehavior: .developerErrors)
  let urlOpener = TestInternalURLOpener()
  let responseFactory = TestBridgeAPIResponseFactory()
  let frameworkLoader = TestDylibResolver()
  let appURLSchemeProvider = TestInternalUtility()
  let errorFactory = TestErrorFactory()

  func testDefaultDependencies() throws {
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
    XCTAssertTrue(
      BridgeAPI.shared.appURLSchemeProvider is InternalUtility,
      "Should use the expected internal utility type by default"
    )

    let factory = try XCTUnwrap(
      BridgeAPI.shared.errorFactory as? ErrorFactory,
      "Should create an error factory"
    )
    XCTAssertTrue(
      factory.reporter === ErrorReporter.shared,
      "Should use the shared error reporter by default"
    )
  }

  func testCreatingWithDependencies() {
    let api = BridgeAPI(
      processInfo: processInfo,
      logger: logger,
      urlOpener: urlOpener,
      bridgeAPIResponseFactory: responseFactory,
      frameworkLoader: frameworkLoader,
      appURLSchemeProvider: appURLSchemeProvider,
      errorFactory: errorFactory
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
      api.urlOpener as? TestInternalURLOpener,
      urlOpener,
      "Should be able to create a bridge api with a specific url opener"
    )
    XCTAssertEqual(
      api.bridgeAPIResponseFactory as? TestBridgeAPIResponseFactory,
      responseFactory,
      "Should be able to create a bridge api with a specific response factory"
    )
    XCTAssertEqual(
      api.frameworkLoader as? TestDylibResolver,
      frameworkLoader,
      "Should be able to create a bridge api with a specific framework loader"
    )
    XCTAssertTrue(
      api.errorFactory === errorFactory,
      "Should be able to create a bridge API instance with an error factory"
    )
  }
}
