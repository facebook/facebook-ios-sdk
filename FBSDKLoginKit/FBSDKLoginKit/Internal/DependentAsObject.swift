/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@dynamicMemberLookup
protocol DependentAsObject: AnyObject {
  associatedtype ObjectDependencies

  var configuredDependencies: ObjectDependencies? { get set }
  var defaultDependencies: ObjectDependencies? { get }

  func setDependencies(_ dependencies: ObjectDependencies)

  #if DEBUG
  func resetDependencies()
  #endif
}

extension DependentAsObject {
  func setDependencies(_ dependencies: ObjectDependencies) {
    configuredDependencies = dependencies
  }

  #if DEBUG
  func resetDependencies() {
    configuredDependencies = nil
  }
  #endif

  func getDependencies() throws -> ObjectDependencies {
    guard let dependencies = configuredDependencies ?? defaultDependencies else {
      throw MissingDependenciesError(for: Self.self)
    }

    return dependencies
  }

  subscript<Dependency>(dynamicMember keyPath: KeyPath<ObjectDependencies, Dependency>) -> Dependency? {
    try? getDependencies()[keyPath: keyPath]
  }
}
