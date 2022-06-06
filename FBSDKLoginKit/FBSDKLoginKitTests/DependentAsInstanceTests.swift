/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit
import XCTest

final class DependentAsInstanceTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  private var defaultImplementationDependent: DefaultImplementationDependent!
  private var customImplementationDependent: CustomImplementationDependent!
  // swiftlint:enable implicitly_unwrapped_optional

  private let defaultDependencies = TestDependencies(value: 14)
  private let customDependencies = TestDependencies(value: 28)

  override func setUp() {
    super.setUp()

    defaultImplementationDependent = DefaultImplementationDependent()
    customImplementationDependent = CustomImplementationDependent()
  }

  override func tearDown() {
    defaultImplementationDependent = nil
    customImplementationDependent = nil

    super.tearDown()
  }

  func testMissingDependencies() {
    XCTAssertThrowsError(
      try defaultImplementationDependent.getDependencies(),
      .missingDependencies
    ) { error in
      XCTAssertEqual(
        String(describing: error),
        "The dependencies for the instance of 'DefaultImplementationDependent' have not been set",
        .missingDependencies
      )
    }
  }

  func testDefaultDependencies() {
    defaultImplementationDependent.defaultDependencies = defaultDependencies
    XCTAssertEqual(
      try defaultImplementationDependent.getDependencies(),
      defaultDependencies,
      .defaultDependencies
    )
  }

  func testConfiguredDependencies() {
    defaultImplementationDependent.defaultDependencies = defaultDependencies
    defaultImplementationDependent.configuredDependencies = customDependencies
    XCTAssertEqual(
      try defaultImplementationDependent.getDependencies(),
      customDependencies,
      .customDependencies
    )
  }

  func testDefaultSetDependencies() {
    defaultImplementationDependent.setDependencies(customDependencies)
    XCTAssertEqual(
      defaultImplementationDependent.configuredDependencies,
      customDependencies,
      .defaultSetDependenciesImplementation
    )
  }

  func testCustomSetDependencies() {
    customImplementationDependent.setDependencies(customDependencies)
    XCTAssertTrue(customImplementationDependent.wasSetDependenciesCalled, .customSetDependenciesImplementation)
  }

  func testDefaultResetDependencies() {
    defaultImplementationDependent.configuredDependencies = customDependencies
    defaultImplementationDependent.resetDependencies()
    XCTAssertNil(defaultImplementationDependent.configuredDependencies, .defaultResetDependenciesImplementation)
  }

  func testCustomResetDependencies() {
    customImplementationDependent.resetDependencies()
    XCTAssertTrue(customImplementationDependent.wasResetDependenciesCalled, .customResetDependenciesImplementation)
  }

  func testFailedDynamicMemberLookup() {
    XCTAssertNil(defaultImplementationDependent.value, .missingDependencyDynamicMemberLookup)
  }

  func testDynamicMemberLookup() {
    defaultImplementationDependent.defaultDependencies = customDependencies
    XCTAssertEqual(
      defaultImplementationDependent.value,
      customDependencies.value,
      .dynamicMemberLookup
    )
  }
}

// MARK: - Test Types

private struct TestDependencies: Equatable {
  let value: Int
}

private final class DefaultImplementationDependent: DependentAsInstance {
  var configuredDependencies: TestDependencies?
  var defaultDependencies: TestDependencies?
}

private final class CustomImplementationDependent: DependentAsInstance {
  var configuredDependencies: TestDependencies?
  var defaultDependencies: TestDependencies?

  var wasSetDependenciesCalled = false
  var wasResetDependenciesCalled = false

  func setDependencies(_ dependencies: TestDependencies) {
    wasSetDependenciesCalled = true
  }

  func resetDependencies() {
    wasResetDependenciesCalled = true
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let missingDependencies = """
    Attempting to get the missing dependencies of a dependent throws a missing instance dependencies error
    """
  static let defaultDependencies = """
    When a dependent's configured dependencies are missing, its default dependencies are provided
    """
  static let customDependencies = "When a dependent has configured dependencies, those dependencies are provided"

  static let defaultSetDependenciesImplementation = """
    A dependent has a default `setDependencies(_:)` implementation that sets its configured dependencies
    """
  static let customSetDependenciesImplementation = """
    A dependent can override the default `setDependencies(_:)` implementation
    """

  static let defaultResetDependenciesImplementation = """
    A dependent has a default `resetDependencies()` implementation that clears its configured dependencies
    """
  static let customResetDependenciesImplementation = """
    A dependent can override the default `resetDependencies()` implementation
    """

  static let missingDependencyDynamicMemberLookup = """
    When a dependent's dependencies are missing, dynamic lookup of a dependency as a property yields a nil value
    """
  static let dynamicMemberLookup = "The discrete dependencies of a dependent can be accessed dynamically as properties"
}
