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
  case unhandledError(status: String?)
}

struct LocalStorage: AuthenticationSessionStatePersisting, UserSessionPersisting {
  static let authenticationStateKey = "com.metasdk.authenticationstate"
  static let userSessionSavedFlagKey = "userSessionKey"
  static let userSessionSavedFlag = 1

  var configuredDependencies: InstanceDependencies?
  var defaultDependencies: InstanceDependencies? {
    .init(
      userSessionMap: UserDefaultsStore(),
      userSessionStore: KeychainStore()
    )
  }

  var authenticationSessionState: AuthenticationSessionState {
    get {
      guard let dependencies = try? getDependencies() else { return .none }

      if let rawValue = dependencies.userSessionMap.getIntegerValue(for: Self.authenticationStateKey) {
        return AuthenticationSessionState(rawValue: rawValue) ?? .none
      } else {
        return .none
      }
    }
    set {
      guard let dependencies = try? getDependencies() else { return }

      dependencies.userSessionMap.set(newValue.rawValue, for: Self.authenticationStateKey)
    }
  }

  func getUserSession() throws -> UserSession {
    let dependencies = try getDependencies()

    // if there is no userSessionKey in user defaults, it means the app was uninstalled or never logged in.
    guard
      let flag = dependencies.userSessionMap.getIntegerValue(for: Self.userSessionSavedFlagKey),
      flag == Self.userSessionSavedFlag
    else {
      // When user uninstalled the app and then installs the app again,
      // keychian may contain stale/invalid UserSession
      // and it need to call deleteUserSession() to remove stale data.
      try deleteUserSession()
      throw LocalStorageError.itemNotFound
    }

    let data = try dependencies.userSessionStore.read()
    return try JSONDecoder().decode(UserSession.self, from: data)
  }

  func saveUserSession(userSession: UserSession) throws {
    let dependencies = try getDependencies()
    let encodedData = try JSONEncoder().encode(userSession)

    try dependencies.userSessionStore.save(encodedData)
    dependencies.userSessionMap.set(Self.userSessionSavedFlag, for: Self.userSessionSavedFlagKey)
  }

  func deleteUserSession() throws {
    let dependencies = try getDependencies()

    try dependencies.userSessionStore.delete()
    dependencies.userSessionMap.remove(for: Self.userSessionSavedFlagKey)
  }
}

extension LocalStorage: DependentAsInstance {
  struct InstanceDependencies {
    var userSessionMap: KeyedValueMapping
    var userSessionStore: DataPersisting
  }
}
