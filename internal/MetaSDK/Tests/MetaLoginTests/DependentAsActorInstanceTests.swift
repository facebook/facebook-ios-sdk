/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import XCTest

final class DependentAsActorInstanceTests: XCTestCase {

  // swiftlint:disable:next implicitly_unwrapped_optional
  private var dependent: Dependent!

  private let defaultDependencies = TestDependencies(value: 14)
  private let customDependencies = TestDependencies(value: 28)

  override func setUp() {
    super.setUp()
    dependent = Dependent()
  }

  override func tearDown() {
    dependent = nil
    super.tearDown()
  }

  func testMissingDependencies() async {
    await dependent.removeDefaultDependencies()

    do {
      _ = try await dependent.getDependencies()
      XCTFail(.missingDependencies)
    } catch {
      XCTAssertEqual(
        String(describing: error),
        "The dependencies for the instance of 'Dependent' have not been set",
        .missingDependencies
      )
    }
  }

  func testDefaultDependencies() async {
    do {
      let dependencies = try await dependent.getDependencies()
      XCTAssertEqual(
        dependencies,
        defaultDependencies,
        .defaultDependencies
      )
    } catch {
      XCTFail(.defaultDependencies)
    }
  }

  func testConfiguredDependencies() async {
    await dependent.setDependencies(customDependencies)

    do {
      let dependencies = try await dependent.getDependencies()
      XCTAssertEqual(
        dependencies,
        customDependencies,
        .configuredDependencies
      )
    } catch {
      XCTFail(.configuredDependencies)
    }
  }
}

// MARK: - Test Types

private struct TestDependencies: Equatable {
  let value: Int
}

private actor Dependent: DependentAsActorInstance {
  var configuredDependencies: TestDependencies?
  var defaultDependencies: TestDependencies? = TestDependencies(value: 14)

  func setDependencies(_ dependencies: TestDependencies) async {
    configuredDependencies = dependencies
  }

  func getDependencies() async throws -> TestDependencies {
    guard let dependencies = configuredDependencies ?? defaultDependencies else {
      throw MissingDependenciesError(for: Self.self)
    }

    return dependencies
  }

  func removeDefaultDependencies() async {
    defaultDependencies = nil
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
  static let configuredDependencies = "When a dependent has configured dependencies, those dependencies are provided"
}
