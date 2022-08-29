/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

actor AuthenticationSessionStateStore: AuthenticationSessionStatePersisting {
  static let authenticationStateKey = "com.metasdk.authenticationstate"

  var configuredDependencies: InstanceDependencies?
  var defaultDependencies: InstanceDependencies? = InstanceDependencies(
    authenticationSessionStateMap: UserDefaultsStore()
  )

  func getAuthenticationSessionState() async -> AuthenticationSessionState? {
    return try? await getDependencies()
      .authenticationSessionStateMap
      .getIntegerValue(for: Self.authenticationStateKey)
      .flatMap(AuthenticationSessionState.init(rawValue:))
  }

  func setAuthenticationSessionState(_ authenticationSessionState: AuthenticationSessionState?) async {
    guard let dependencies = try? await getDependencies() else { return }

    if let state = authenticationSessionState {
      dependencies.authenticationSessionStateMap.set(state.rawValue, for: Self.authenticationStateKey)
    } else {
      dependencies.authenticationSessionStateMap.remove(for: Self.authenticationStateKey)
    }
  }
}

extension AuthenticationSessionStateStore: DependentAsActorInstance {
  struct InstanceDependencies {
    var authenticationSessionStateMap: KeyedValueMapping
  }

  func setDependencies(_ dependencies: InstanceDependencies) async {
    configuredDependencies = dependencies
  }

  func getDependencies() async throws -> InstanceDependencies {
    guard let dependencies = configuredDependencies ?? defaultDependencies else {
      throw MissingDependenciesError(for: Self.self)
    }
    return dependencies
  }
}
