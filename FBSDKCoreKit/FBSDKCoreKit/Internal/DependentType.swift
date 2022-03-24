/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

protocol DependentType {
  associatedtype Dependencies

  static var configuredDependencies: Dependencies? { get set }
  static var defaultDependencies: Dependencies? { get }

  static func setDependencies(_ dependencies: Dependencies)

  #if DEBUG
  static func resetDependencies()
  #endif
}

extension DependentType {
  static func setDependencies(_ dependencies: Dependencies) {
    configuredDependencies = dependencies
  }

  #if DEBUG
  static func resetDependencies() {
    configuredDependencies = nil
  }
  #endif

  static func getDependencies() throws -> Dependencies {
    guard let dependencies = configuredDependencies ?? defaultDependencies else {
      throw MissingTypeDependenciesError(for: Self.self)
    }

    return dependencies
  }
}

struct MissingTypeDependenciesError<Dependent: DependentType>: Error, CustomStringConvertible {
  private var dependentType: Dependent.Type

  fileprivate init(for dependentType: Dependent.Type) {
    self.dependentType = dependentType
  }

  var description: String {
    "The dependencies for the type '\(dependentType)' have not been set"
  }
}
