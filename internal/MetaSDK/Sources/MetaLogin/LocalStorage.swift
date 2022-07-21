// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

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
