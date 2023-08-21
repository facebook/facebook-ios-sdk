/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class TokenCache: TokenCaching {

  private enum Keys {
    static let accessTokenUserDefaults = "com.facebook.sdk.v4.FBSDKAccessTokenInformationKey"
    static let accessTokenKeychain = "com.facebook.sdk.v4.FBSDKAccessTokenInformationKeychainKey"
    static let authenticationTokenUserDefaults = "com.facebook.sdk.v9.FBSDKAuthenticationTokenInformationKey"
    static let authenticationTokenKeychain = "com.facebook.sdk.v9.FBSDKAuthenticationTokenInformationKeychainKey"
    static let tokenUUID = "tokenUUID"
    static let encodedToken = "tokenEncoded"
  }

  var configuredDependencies: ObjectDependencies?
  var defaultDependencies: ObjectDependencies?

  var accessToken: AccessToken? {
    get {
      guard let dependencies = try? getDependencies() else {
        return nil
      }

      let uuid = dependencies.dataStore.fb_string(forKey: Keys.accessTokenUserDefaults)
      let keychainStoreRepresentation = dependencies.keychainStore.dictionary(forKey: Keys.accessTokenKeychain)

      if dependencies.settings.shouldUseTokenOptimizations {
        if uuid == nil,
           keychainStoreRepresentation == nil {
          return nil
        }

        if uuid == nil {
          clearAccessTokenCache()
          return nil
        }

        if keychainStoreRepresentation == nil {
          dependencies.dataStore.fb_removeObject(forKey: Keys.accessTokenUserDefaults)
          return nil
        }
      }

      guard
        let keychainStoreRepresentation = keychainStoreRepresentation,
        let tokenUUID = keychainStoreRepresentation[Keys.tokenUUID] as? String,
        // We check if the UUID from the defaults and the keychain match to see if the token has
        // changed or missing which could mean the app was uninstalled.
        tokenUUID == uuid,
        let tokenData = keychainStoreRepresentation[Keys.encodedToken] as? Data,
        let unarchiver = try? createUnarchiver(for: tokenData),
        let unarchivedToken = unarchiver.decodeObject(of: AccessToken.self, forKey: NSKeyedArchiveRootObjectKey)
      else {
        clearAccessTokenCache()
        return nil
      }

      return unarchivedToken
    }

    set {
      guard
        let dependencies = try? getDependencies(),
        let token = newValue
      else { return clearAccessTokenCache() }

      var uuid = dependencies.dataStore.fb_object(forKey: Keys.accessTokenUserDefaults) as? String
      if uuid == nil {
        uuid = UUID().uuidString
        dependencies.dataStore.fb_setObject(
          uuid as Any,
          forKey: Keys.accessTokenUserDefaults
        )
      }

      let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: false)
      let keychainRepresentation = [
        Keys.tokenUUID: uuid as Any,
        Keys.encodedToken: tokenData as Any,
      ] as [String: Any]

      dependencies.keychainStore.setDictionary(
        keychainRepresentation,
        forKey: Keys.accessTokenKeychain,
        accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
      )
    }
  }

  var authenticationToken: AuthenticationToken? {
    get {
      guard let dependencies = try? getDependencies() else { return nil }

      let uuid = dependencies.dataStore.fb_object(forKey: Keys.authenticationTokenUserDefaults) as? String
      let keychainRepresentation = dependencies.keychainStore.dictionary(forKey: Keys.authenticationTokenKeychain)

      if dependencies.settings.shouldUseTokenOptimizations {
        if uuid == nil,
           keychainRepresentation == nil {
          return nil
        }

        if uuid == nil {
          clearAuthenticationTokenCache()
          return nil
        }

        if keychainRepresentation == nil {
          dependencies.dataStore.fb_removeObject(forKey: Keys.authenticationTokenUserDefaults)
          return nil
        }
      }

      guard
        let keychainRepresentation = keychainRepresentation,
        let tokenUUID = keychainRepresentation[Keys.tokenUUID] as? String,
        // We check if the UUID from the defaults and the keychain match to see if the token has
        // changed or missing which could mean the app was uninstalled.
        tokenUUID == uuid
      else {
        clearAuthenticationTokenCache()
        return nil
      }

      guard
        let tokenData = keychainRepresentation[Keys.encodedToken] as? Data,
        let unarchiver = try? createUnarchiver(for: tokenData),
        let unarchivedToken = unarchiver.decodeObject(of: AuthenticationToken.self, forKey: NSKeyedArchiveRootObjectKey)
      else {
        return nil
      }

      return unarchivedToken
    }

    set {
      guard
        let dependencies = try? getDependencies(),
        let token = newValue
      else {
        clearAuthenticationTokenCache()
        return
      }

      var uuid = dependencies.dataStore.fb_object(forKey: Keys.authenticationTokenUserDefaults) as? String

      if uuid == nil {
        uuid = UUID().uuidString
        dependencies.dataStore.fb_setObject(
          uuid as Any,
          forKey: Keys.authenticationTokenUserDefaults
        )
      }

      let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: false)

      let keychainRepresentation = [
        Keys.tokenUUID: uuid as Any,
        Keys.encodedToken: tokenData as Any,
      ] as [String: Any]

      dependencies.keychainStore.setDictionary(
        keychainRepresentation,
        forKey: Keys.authenticationTokenKeychain,
        accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
      )
    }
  }

  private func clearAuthenticationTokenCache() {
    let dependencies = try? getDependencies()
    dependencies?.keychainStore.setDictionary(nil, forKey: Keys.authenticationTokenKeychain, accessibility: nil)
    UserDefaults.standard.removeObject(forKey: Keys.authenticationTokenUserDefaults)
  }

  private func clearAccessTokenCache() {
    let dependencies = try? getDependencies()
    dependencies?.keychainStore.setDictionary(nil, forKey: Keys.accessTokenKeychain, accessibility: nil)
    UserDefaults.standard.removeObject(forKey: Keys.accessTokenUserDefaults)
  }

  private func createUnarchiver(for data: Data) throws -> NSKeyedUnarchiver {
    let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
    unarchiver.requiresSecureCoding = true
    return unarchiver
  }
}

extension TokenCache: DependentAsObject {
  struct ObjectDependencies {
    let settings: SettingsProtocol
    let keychainStore: KeychainStoreProtocol
    let dataStore: DataPersisting
  }
}
