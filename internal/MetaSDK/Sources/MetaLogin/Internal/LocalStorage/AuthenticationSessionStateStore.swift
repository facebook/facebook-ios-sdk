/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

struct AuthenticationSessionStateStore: AuthenticationSessionStatePersisting {
  static let authenticationStateKey = "com.metasdk.authenticationstate"

  var configuredDependencies: InstanceDependencies?
  var defaultDependencies: InstanceDependencies? = InstanceDependencies(
    authenticationSessionStateMap: UserDefaultsStore()
  )

  var authenticationSessionState: AuthenticationSessionState? {
    get {
      try? getDependencies()
        .authenticationSessionStateMap
        .getIntegerValue(for: Self.authenticationStateKey)
        .flatMap(AuthenticationSessionState.init(rawValue:))
    }
    set {
      guard let dependencies = try? getDependencies() else { return }

      if let state = newValue {
        dependencies.authenticationSessionStateMap.set(state.rawValue, for: Self.authenticationStateKey)
      } else {
        dependencies.authenticationSessionStateMap.remove(for: Self.authenticationStateKey)
      }
    }
  }
}

extension AuthenticationSessionStateStore: DependentAsInstance {
  struct InstanceDependencies {
    var authenticationSessionStateMap: KeyedValueMapping
  }
}
