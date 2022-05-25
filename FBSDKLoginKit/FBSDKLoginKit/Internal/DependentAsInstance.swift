/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

protocol DependentAsInstance {
  associatedtype InstanceDependencies

  var configuredDependencies: InstanceDependencies? { get set }
  var defaultDependencies: InstanceDependencies? { get }

  mutating func setDependencies(_ dependencies: InstanceDependencies)

  #if DEBUG
  mutating func resetDependencies()
  #endif
}

extension DependentAsInstance {
  mutating func setDependencies(_ dependencies: InstanceDependencies) {
    configuredDependencies = dependencies
  }

  #if DEBUG
  mutating func resetDependencies() {
    configuredDependencies = nil
  }
  #endif

  func getDependencies() throws -> InstanceDependencies {
    guard let dependencies = configuredDependencies ?? defaultDependencies else {
      throw MissingInstanceDependenciesError(for: Self.self)
    }

    return dependencies
  }
}

struct MissingInstanceDependenciesError<Dependent: DependentAsInstance>: Error, CustomStringConvertible {
  private var dependentType: Dependent.Type

  fileprivate init(for dependentType: Dependent.Type) {
    self.dependentType = dependentType
  }

  var description: String {
    "The dependencies for the instance of '\(dependentType)' have not been set"
  }
}
