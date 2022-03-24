/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import XCTest

final class DependentTypeTests: XCTestCase {

  let defaultDependencies = TestDependencies(value: 14)
  let customDependencies = TestDependencies(value: 28)

  override func setUp() {
    super.setUp()

    DefaultImplementationDependent.configuredDependencies = nil
    DefaultImplementationDependent.defaultDependencies = nil

    CustomImplementationDependent.configuredDependencies = nil
    CustomImplementationDependent.wasSetDependenciesCalled = false
    CustomImplementationDependent.wasResetDependenciesCalled = false
  }

  override func tearDown() {
    DefaultImplementationDependent.configuredDependencies = nil
    DefaultImplementationDependent.defaultDependencies = nil

    CustomImplementationDependent.configuredDependencies = nil
    CustomImplementationDependent.wasSetDependenciesCalled = false
    CustomImplementationDependent.wasResetDependenciesCalled = false

    super.tearDown()
  }

  func testMissingDependencies() throws {
    XCTAssertThrowsError(
      try DefaultImplementationDependent.getDependencies(),
      .missingDependencies
    ) { error in
      XCTAssertEqual(
        String(describing: error),
        "The dependencies for the type 'DefaultImplementationDependent' have not been set",
        .missingDependencies
      )
    }
  }

  func testDefaultDependencies() throws {
    DefaultImplementationDependent.defaultDependencies = defaultDependencies
    XCTAssertEqual(
      try DefaultImplementationDependent.getDependencies(),
      defaultDependencies,
      .defaultDependencies
    )
  }

  func testConfiguredDependencies() throws {
    DefaultImplementationDependent.defaultDependencies = defaultDependencies
    DefaultImplementationDependent.configuredDependencies = customDependencies
    XCTAssertEqual(
      try DefaultImplementationDependent.getDependencies(),
      customDependencies,
      .customDependencies
    )
  }

  func testDefaultSetDependencies() throws {
    DefaultImplementationDependent.setDependencies(customDependencies)
    XCTAssertEqual(
      DefaultImplementationDependent.configuredDependencies,
      customDependencies,
      .defaultSetDependenciesImplementation
    )
  }

  func testCustomSetDependencies() throws {
    CustomImplementationDependent.setDependencies(customDependencies)
    XCTAssertTrue(CustomImplementationDependent.wasSetDependenciesCalled, .customSetDependenciesImplementation)
  }

  func testDefaultResetDependencies() {
    DefaultImplementationDependent.configuredDependencies = customDependencies
    DefaultImplementationDependent.resetDependencies()
    XCTAssertNil(DefaultImplementationDependent.configuredDependencies, .defaultResetDependenciesImplementation)
  }

  func testCustomResetDependencies() {
    CustomImplementationDependent.resetDependencies()
    XCTAssertTrue(CustomImplementationDependent.wasResetDependenciesCalled, .customResetDependenciesImplementation)
  }
}

// MARK: - Test Configurable Types

struct TestDependencies: Equatable {
  let value: Int
}

enum DefaultImplementationDependent: DependentType {
  static var configuredDependencies: TestDependencies?
  static var defaultDependencies: TestDependencies?
}

enum CustomImplementationDependent: DependentType {
  static var configuredDependencies: TestDependencies?
  static var defaultDependencies: TestDependencies?

  static var wasSetDependenciesCalled = false
  static var wasResetDependenciesCalled = false

  static func setDependencies(_ dependencies: TestDependencies) {
    wasSetDependenciesCalled = true
  }

  static func resetDependencies() {
    wasResetDependenciesCalled = true
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let missingDependencies = """
    Attempting to get the missing dependencies of a dependent type should throw a missing type dependencies error
    """
  static let defaultDependencies = """
    If a dependent type's configured dependencies are missing, its default dependencies should be provided
    """
  static let customDependencies = """
    If a dependent type has configured dependencies, those dependencies should be provided
    """

  static let defaultSetDependenciesImplementation = """
    A dependent type should have a default `setDependencies(_:)` implementation that sets its configured dependencies
    """
  static let customSetDependenciesImplementation = """
    A dependent type should be able to override the default `setDependencies(_:)` implementation
    """

  static let defaultResetDependenciesImplementation = """
    A dependent type should have a default `resetDependencies()` implementation that clears its configured dependencies
    """
  static let customResetDependenciesImplementation = """
    A dependent type should be able to override the default `resetDependencies()` implementation
    """
}
