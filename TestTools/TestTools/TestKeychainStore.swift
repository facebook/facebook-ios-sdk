/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
public final class TestKeychainStore: NSObject, KeychainStoreProtocol {
  public var service: String?
  public var accessGroup: String?
  public var wasStringForKeyCalled = false
  public var wasSetStringCalled = false
  public var value: String?
  public var key: String?
  public var keychainDictionary: [String: String] = [:]
  public var wasDictionaryForKeyCalled = false
  public var wasSetDictionaryCalled = false

  public convenience init(
    service: String,
    accessGroup: String?
  ) {
    self.init()
    self.service = service
    self.accessGroup = accessGroup
  }

  public func string(forKey key: String) -> String? {
    wasStringForKeyCalled = true
    return keychainDictionary[key]
  }

  public func setString(_ value: String?, forKey key: String, accessibility: CFTypeRef?) -> Bool {
    keychainDictionary[key] = value
    wasSetStringCalled = true
    return true
  }

  public func dictionary(forKey key: String) -> [String: Any]? {
    wasDictionaryForKeyCalled = true
    return [:]
  }

  public func setDictionary(_ value: [String: Any]?, forKey key: String, accessibility: CFTypeRef?) -> Bool {
    wasSetDictionaryCalled = true
    return true
  }
}
