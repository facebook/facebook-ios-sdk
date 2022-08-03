/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum LocalStorageError: Error {
    case itemNotFound
    case decodingError(Error)
    case encodingError(Error)
    case unhandledError(status: OSStatus)
    case dependencyError
}

struct LocalStorage: AuthenticationSessionStatePersisting, UserSessionPersisting {
    static let authenticationStateKey = "com.metasdk.authenticationstate"
    static let userSessionSavedFlagKey = "userSessionKey"
    static let userSessionSavedFlag = 1

    var configuredDependencies: InstanceDependencies?
    var defaultDependencies: InstanceDependencies? {
        .init(
            dataStorage: UserDefaults.standard,
            keychainStorage: KeychainStorage()
        )
    }

    var authenticationSessionState: AuthenticationSessionState {
        get {
            guard let dependencies = try? getDependencies() else { return .none }
            let rawValue = dependencies.dataStorage.integer(forKey: Self.authenticationStateKey)

            return AuthenticationSessionState(rawValue: rawValue) ?? .none
        }
        set {
            guard let dependencies = try? getDependencies() else { return }

            dependencies.dataStorage.set(newValue.rawValue, forKey: Self.authenticationStateKey)
        }
    }

    func getUserSession() throws -> UserSession {
        guard let dependencies = try? getDependencies() else { throw LocalStorageError.dependencyError}

        // if there is no userSessionKey in user defaults, it means the app was uninstalled or never logged in.
        guard dependencies.dataStorage.integer(forKey: Self.userSessionSavedFlagKey) == Self.userSessionSavedFlag else {
            // When user uninstalled the app and then installs the app again,
            // keychian may contain stale/invalid UserSession
            // and it need to call deleteUserSession() to remove stale data.
            try deleteUserSession()
            throw LocalStorageError.itemNotFound
        }

        let keychainResponse = dependencies.keychainStorage.read()

        // Check if item is existed
        guard keychainResponse.status != errSecItemNotFound else {
            throw LocalStorageError.itemNotFound
        }

        guard keychainResponse.status == noErr else {
            throw LocalStorageError.unhandledError(status: keychainResponse.status)
        }

        guard let data = keychainResponse.data else {
            throw LocalStorageError.itemNotFound
        }

        do {
            return try JSONDecoder().decode(UserSession.self, from: data)
        } catch {
            throw LocalStorageError.decodingError(error)
        }
    }

    func saveUserSession(userSession: UserSession) throws {
        guard let dependencies = try? getDependencies() else { throw LocalStorageError.dependencyError }
        let encodedData: Data
        do {
            encodedData = try JSONEncoder().encode(userSession)
        } catch {
            throw LocalStorageError.encodingError(error)
        }

        let status = dependencies.keychainStorage.save(data: encodedData)

        guard status == noErr else {
            throw LocalStorageError.unhandledError(status: status)
        }

        dependencies.dataStorage.set(
            Self.userSessionSavedFlag,
            forKey: Self.userSessionSavedFlagKey
        )
    }

    func deleteUserSession() throws {
        guard let dependencies = try? getDependencies() else { throw LocalStorageError.dependencyError }
        let status = dependencies.keychainStorage.delete()
        dependencies.dataStorage.removeObject(forKey: Self.userSessionSavedFlagKey)

        // Throw an error if an unexpected status was returned.
        guard status == noErr || status == errSecItemNotFound else {
            throw LocalStorageError.unhandledError(status: status)
        }
    }
}

extension LocalStorage: DependentAsInstance {
    struct InstanceDependencies {
        var dataStorage: DataPersisting
        var keychainStorage: KeychainPersisting
    }
}
