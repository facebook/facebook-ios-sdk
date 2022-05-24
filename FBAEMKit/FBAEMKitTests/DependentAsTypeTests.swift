/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBAEMKit
import XCTest

final class DependentAsTypeTests: XCTestCase {

  private let defaultDependencies = TestDependencies(value: 14)
  private let customDependencies = TestDependencies(value: 28)

  override func setUp() {
    super.setUp()
    resetDependencies()
  }

  override func tearDown() {
    resetDependencies()
    super.tearDown()
  }

  private func resetDependencies() {
    DefaultImplementationDependent.configuredDependencies = nil
    DefaultImplementationDependent.defaultDependencies = nil

    CustomImplementationDependent.configuredDependencies = nil
    CustomImplementationDependent.wasSetDependenciesCalled = false
    CustomImplementationDependent.wasResetDependenciesCalled = false
  }

  func testMissingDependencies() {
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

  func testDefaultDependencies() {
    DefaultImplementationDependent.defaultDependencies = defaultDependencies
    XCTAssertEqual(
      try DefaultImplementationDependent.getDependencies(),
      defaultDependencies,
      .defaultDependencies
    )
  }

  func testConfiguredDependencies() {
    DefaultImplementationDependent.defaultDependencies = defaultDependencies
    DefaultImplementationDependent.configuredDependencies = customDependencies
    XCTAssertEqual(
      try DefaultImplementationDependent.getDependencies(),
      customDependencies,
      .customDependencies
    )
  }

  func testDefaultSetDependencies() {
    DefaultImplementationDependent.setDependencies(customDependencies)
    XCTAssertEqual(
      DefaultImplementationDependent.configuredDependencies,
      customDependencies,
      .defaultSetDependenciesImplementation
    )
  }

  func testCustomSetDependencies() {
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

// MARK: - Test Types

struct TestDependencies: Equatable {
  let value: Int
}

private enum DefaultImplementationDependent: DependentAsType {
  static var configuredDependencies: TestDependencies?
  static var defaultDependencies: TestDependencies?
}

private enum CustomImplementationDependent: DependentAsType {
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
    Attempting to get the missing dependencies of a dependent should throw a missing type dependencies error
    """
  static let defaultDependencies = """
    If a dependent's configured dependencies are missing, its default dependencies should be provided
    """
  static let customDependencies = """
    If a dependent has configured dependencies, those dependencies should be provided
    """

  static let defaultSetDependenciesImplementation = """
    A dependent should have a default `setDependencies(_:)` implementation that sets its configured dependencies
    """
  static let customSetDependenciesImplementation = """
    A dependent should be able to override the default `setDependencies(_:)` implementation
    """

  static let defaultResetDependenciesImplementation = """
    A dependent should have a default `resetDependencies()` implementation that clears its configured dependencies
    """
  static let customResetDependenciesImplementation = """
    A dependent should be able to override the default `resetDependencies()` implementation
    """
}
