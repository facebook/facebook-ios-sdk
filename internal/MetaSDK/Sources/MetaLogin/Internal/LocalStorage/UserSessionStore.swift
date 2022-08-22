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

actor UserSessionStore: UserSessionPersisting {
  static let userSessionSavedFlagKey = "userSessionKey"
  static let userSessionSavedFlag = 1

  var configuredDependencies: InstanceDependencies?
  var defaultDependencies: InstanceDependencies? = InstanceDependencies(
    userSessionMap: UserDefaultsStore(),
    userSessionStorage: KeychainStore()
  )

  func getUserSession() async throws -> UserSession {
    let dependencies = try await getDependencies()

    // if there is no userSessionKey in user defaults, it means the app was uninstalled or never logged in.
    guard
      let flag = dependencies.userSessionMap.getIntegerValue(for: Self.userSessionSavedFlagKey),
      flag == Self.userSessionSavedFlag
    else {
      // When user uninstalled the app and then installs the app again,
      // keychian may contain stale/invalid UserSession
      // and it need to call deleteUserSession() to remove stale data.
      try await deleteUserSession()
      throw LocalStorageError.itemNotFound
    }

    let data = try dependencies.userSessionStorage.read()
    return try JSONDecoder().decode(UserSession.self, from: data)
  }

  func saveUserSession(_ userSession: UserSession) async throws {
    let dependencies = try await getDependencies()
    let encodedData = try JSONEncoder().encode(userSession)

    try dependencies.userSessionStorage.save(encodedData)
    dependencies.userSessionMap.set(Self.userSessionSavedFlag, for: Self.userSessionSavedFlagKey)
  }

  func deleteUserSession() async throws {
    let dependencies = try await getDependencies()

    try dependencies.userSessionStorage.delete()
    dependencies.userSessionMap.remove(for: Self.userSessionSavedFlagKey)
  }
}

extension UserSessionStore: DependentAsActorInstance {
  struct InstanceDependencies {
    var userSessionMap: KeyedValueMapping
    var userSessionStorage: DataPersisting
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
