/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

struct LocalStorage: AuthenticationSessionStatePersisting {
    static let persistenceKey = "com.metasdk.authenticationstate"
    var configuredDependencies: InstanceDependencies?
    var defaultDependencies: InstanceDependencies? {
        .init(
            dataStorage: UserDefaults.standard)
    }

    var authenticationSessionState: AuthenticationSessionState {
        get {
            guard let dependencies = try? getDependencies() else { return .none }
            let rawValue = dependencies.dataStorage.integer(forKey: Self.persistenceKey)

            return AuthenticationSessionState(rawValue: rawValue) ?? .none
        }
        set {
            guard let dependencies = try? getDependencies() else { return }

            dependencies.dataStorage.set(newValue.rawValue, forKey: Self.persistenceKey)
        }
    }
}

extension LocalStorage: DependentAsInstance {
    struct InstanceDependencies {
        var dataStorage: DataPersisting
    }
}
