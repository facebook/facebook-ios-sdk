/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

@objcMembers
public class TestKeychainStoreFactory: NSObject, KeychainStoreProviding {

  public var capturedService: String?
  public var capturedAccessGroup: String?
  public var stubbedKeychainStore: TestKeychainStore?

  public func createKeychainStore(
    withService service: String,
    accessGroup: String?
  ) -> KeychainStoreProtocol {
    capturedService = service
    capturedAccessGroup = accessGroup

    return stubbedKeychainStore ?? TestKeychainStore(
      service: service,
      accessGroup: accessGroup
    )
  }
}
