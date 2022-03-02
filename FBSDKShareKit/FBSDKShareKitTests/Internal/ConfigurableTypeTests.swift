/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit
import XCTest

final class ConfigurableTypeTests: XCTestCase {

  let defaultDependencies = TestDependencies(value: 14)
  let customDependencies = TestDependencies(value: 28)

  override func setUp() {
    super.setUp()

    DefaultImplementationConfigurable.configuredDependencies = nil
    DefaultImplementationConfigurable.defaultDependencies = nil

    CustomImplementationConfigurable.configuredDependencies = nil
    CustomImplementationConfigurable.wasConfigureCalled = false
    CustomImplementationConfigurable.wasUnconfigureCalled = false
  }

  override func tearDown() {
    DefaultImplementationConfigurable.configuredDependencies = nil
    DefaultImplementationConfigurable.defaultDependencies = nil

    CustomImplementationConfigurable.configuredDependencies = nil
    CustomImplementationConfigurable.wasConfigureCalled = false
    CustomImplementationConfigurable.wasUnconfigureCalled = false

    super.tearDown()
  }

  func testMissingDependencies() throws {
    XCTAssertThrowsError(
      try DefaultImplementationConfigurable.getDependencies(),
      .missingDependencies
    ) { error in
      XCTAssertEqual(
        String(describing: error),
        "The type 'DefaultImplementationConfigurable' has not been configured",
        .missingDependencies
      )
    }
  }

  func testDefaultDependencies() throws {
    DefaultImplementationConfigurable.defaultDependencies = defaultDependencies
    XCTAssertEqual(
      try DefaultImplementationConfigurable.getDependencies(),
      defaultDependencies,
      .defaultDependencies
    )
  }

  func testConfiguredDependencies() throws {
    DefaultImplementationConfigurable.defaultDependencies = defaultDependencies
    DefaultImplementationConfigurable.configuredDependencies = customDependencies
    XCTAssertEqual(
      try DefaultImplementationConfigurable.getDependencies(),
      customDependencies,
      .customDependencies
    )
  }

  func testDefaultConfigure() throws {
    DefaultImplementationConfigurable.configure(with: customDependencies)
    XCTAssertEqual(
      DefaultImplementationConfigurable.configuredDependencies,
      customDependencies,
      .defaultConfigureImplementation
    )
  }

  func testCustomConfigure() throws {
    CustomImplementationConfigurable.configure(with: customDependencies)
    XCTAssertTrue(CustomImplementationConfigurable.wasConfigureCalled, .customConfigureImplementation)
  }

  func testDefaultUnconfigure() {
    DefaultImplementationConfigurable.configuredDependencies = customDependencies
    DefaultImplementationConfigurable.unconfigure()
    XCTAssertNil(DefaultImplementationConfigurable.configuredDependencies, .defaultUncofigureImplementation)
  }

  func testCustomUnconfigure() {
    CustomImplementationConfigurable.unconfigure()
    XCTAssertTrue(CustomImplementationConfigurable.wasUnconfigureCalled, .customUnconfigureImplementation)
  }
}

// MARK: - Test Configurable Types

struct TestDependencies: Equatable {
  let value: Int
}

enum DefaultImplementationConfigurable: _ConfigurableType {
  static var configuredDependencies: TestDependencies?
  static var defaultDependencies: TestDependencies?
}

enum CustomImplementationConfigurable: _ConfigurableType {
  static var configuredDependencies: TestDependencies?
  static var defaultDependencies: TestDependencies?

  static var wasConfigureCalled = false
  static var wasUnconfigureCalled = false

  static func configure(with dependencies: TestDependencies) {
    wasConfigureCalled = true
  }

  static func unconfigure() {
    wasUnconfigureCalled = true
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let missingDependencies = """
    Attempting to get the missing dependencies of a configurable type should throw an unconfigured type error
    """
  static let defaultDependencies = """
    If a type's configured dependencies are missing, its default dependencies should be provided
    """
  static let customDependencies = """
    If a type has configured dependencies, those dependencies should be provided
    """

  static let defaultConfigureImplementation = """
    A configurable type should have a default `configure(with:)` implementation that sets its dependencies
    """
  static let customConfigureImplementation = """
    A configurable type should be able to override the default `configure(with:)` implementation
    """

  static let defaultUncofigureImplementation = """
    A configurable type should have a default `unconfigure()` implementation that clears its dependencies
    """
  static let customUnconfigureImplementation = """
    A configurable type should be able to override the default `unconfigure()` implementation
    """
}
