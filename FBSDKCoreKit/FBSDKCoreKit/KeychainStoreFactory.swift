/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 A factory for providing objects that conform to `KeychainStore`
 */
public final class KeychainStoreFactory: KeychainStoreProviding {

  public init() {}

  public func createKeychainStore(service: String, accessGroup: String?) -> KeychainStoreProtocol {
    KeychainStore(service: service, accessGroup: accessGroup)
  }
}
