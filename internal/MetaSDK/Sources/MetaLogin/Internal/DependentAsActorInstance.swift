/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 This protocol supports dependency injection for actor instances, but the two main methods must be implemented by all
 adopters since actors cannot inherit a default implementation from the protocol.  Use the exact implementations below
 in all adopters after declaring the two properties:

 ```
 func setDependencies(_ dependencies: InstanceDependencies) async {
   configuredDependencies = dependencies
 }

 func getDependencies() async throws -> InstanceDependencies {
   guard let dependencies = configuredDependencies ?? defaultDependencies else {
     throw MissingDependenciesError(for: Self.self)
   }

   return dependencies
 }
 ```
 */
protocol DependentAsActorInstance: Actor {
  associatedtype InstanceDependencies

  var configuredDependencies: InstanceDependencies? { get set }
  var defaultDependencies: InstanceDependencies? { get set }

  func setDependencies(_ dependencies: InstanceDependencies) async
  func getDependencies() async throws -> InstanceDependencies
}
