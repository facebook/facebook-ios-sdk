/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@dynamicMemberLookup
protocol DependentAsValue {
  associatedtype ValueDependencies

  var configuredDependencies: ValueDependencies? { get set }
  var defaultDependencies: ValueDependencies? { get }

  mutating func setDependencies(_ dependencies: ValueDependencies)

  #if DEBUG
  mutating func resetDependencies()
  #endif
}

extension DependentAsValue {
  mutating func setDependencies(_ dependencies: ValueDependencies) {
    configuredDependencies = dependencies
  }

  #if DEBUG
  mutating func resetDependencies() {
    configuredDependencies = nil
  }
  #endif

  func getDependencies() throws -> ValueDependencies {
    guard let dependencies = configuredDependencies ?? defaultDependencies else {
      throw MissingDependenciesError(for: Self.self)
    }

    return dependencies
  }

  subscript<Dependency>(dynamicMember keyPath: KeyPath<ValueDependencies, Dependency>) -> Dependency? {
    try? getDependencies()[keyPath: keyPath]
  }
}
