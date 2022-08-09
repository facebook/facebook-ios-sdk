/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

struct KeychainStorage: KeychainPersisting {
  let keychainService = "com.metasdk.usersessioncache"
  var bundle: Bundle
  var keychainAccount: String {
    bundle.bundleIdentifier ?? "unknown"
  }

  init(bundle: Bundle = Bundle.main) {
    self.bundle = bundle
  }

  func save(data: Data) -> OSStatus {
    let addQuery = [
      kSecAttrService: keychainService,
      kSecAttrAccount: keychainAccount,
      kSecValueData: data,
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
    ] as CFDictionary
    let status = SecItemAdd(addQuery as CFDictionary, nil)

    if status == errSecDuplicateItem {
      let updateQuery = [
        kSecAttrService: keychainService,
        kSecAttrAccount: keychainAccount,
        kSecClass: kSecClassGenericPassword,
      ] as CFDictionary
      let attributesToUpdate = [kSecValueData: data] as CFDictionary
      return SecItemUpdate(updateQuery, attributesToUpdate)
    }
    return status
  }

  func read() -> KeychainResult {
    let readQuery = [
      kSecAttrService: keychainService,
      kSecAttrAccount: keychainAccount,
      kSecClass: kSecClassGenericPassword,
      kSecReturnData: true,
    ] as CFDictionary

    var queryResult: AnyObject?
    let status = SecItemCopyMatching(readQuery, &queryResult)
    return KeychainResult(status: status, data: queryResult as? Data)
  }

  func delete() -> OSStatus {
    let deleteQuery = [
      kSecAttrService: keychainService,
      kSecAttrAccount: keychainAccount,
      kSecClass: kSecClassGenericPassword,
    ] as CFDictionary
    return SecItemDelete(deleteQuery)
  }
}
