/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class KeychainStore: DataPersisting {
  let keychainService = "com.metasdk.usersessioncache"
  var bundle: Bundle
  var keychainAccount: String {
    bundle.bundleIdentifier ?? "unknown"
  }

  init(bundle: Bundle = Bundle.main) {
    self.bundle = bundle
  }

  func save(_ data: Data) throws {
    let addQuery = [
      kSecAttrService: keychainService,
      kSecAttrAccount: keychainAccount,
      kSecValueData: data,
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
    ] as CFDictionary
    var status = SecItemAdd(addQuery as CFDictionary, nil)

    if status == errSecDuplicateItem {
      let updateQuery = [
        kSecAttrService: keychainService,
        kSecAttrAccount: keychainAccount,
        kSecClass: kSecClassGenericPassword,
      ] as CFDictionary
      let attributesToUpdate = [kSecValueData: data] as CFDictionary
      status = SecItemUpdate(updateQuery, attributesToUpdate)
    }

    guard status == errSecSuccess else {
      throw LocalStorageError.unhandledError(status: SecCopyErrorMessageString(status, nil) as? String)
    }
  }

  func read() throws -> Data {
    let readQuery = [
      kSecAttrService: keychainService,
      kSecAttrAccount: keychainAccount,
      kSecClass: kSecClassGenericPassword,
      kSecReturnData: true,
    ] as CFDictionary

    var queryResult: AnyObject?
    let status = SecItemCopyMatching(readQuery, &queryResult)
    let queryData = queryResult as? Data

    if let data = queryData,
       status == errSecSuccess {
      return data
    } else if status == errSecItemNotFound {
      throw LocalStorageError.itemNotFound
    } else {
      throw LocalStorageError.unhandledError(status: SecCopyErrorMessageString(status, nil) as? String)
    }
  }

  func delete() throws {
    let deleteQuery = [
      kSecAttrService: keychainService,
      kSecAttrAccount: keychainAccount,
      kSecClass: kSecClassGenericPassword,
    ] as CFDictionary
    let status = SecItemDelete(deleteQuery)

    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw LocalStorageError.unhandledError(status: SecCopyErrorMessageString(status, nil) as? String)
    }
  }
}
