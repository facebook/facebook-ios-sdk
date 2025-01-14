/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
public final class UserDefaultsSpy: UserDefaults {
  public var capturedObjectRetrievalKeys = [String]()
  public var capturedSetObjectKeys = [String]()
  public var capturedRemoveObjectKeys = [String]()
  public var capturedObjectRetrievalKey: String?
  public var capturedSetObjectKey: String?
  public var capturedValues = [String: Any]()

  public var stringForKeyCallback: ((String) -> String)? = { $0 }

  public override func string(forKey defaultName: String) -> String? {
    stringForKeyCallback?(defaultName)
  }

  public override func object(forKey defaultName: String) -> Any? {
    capturedObjectRetrievalKey = defaultName
    capturedObjectRetrievalKeys.append(defaultName)
    return capturedValues[defaultName]
  }

  public override func set(_ value: Any?, forKey defaultName: String) {
    capturedValues[defaultName] = value
    capturedSetObjectKeys.append(defaultName)
    capturedSetObjectKey = defaultName
  }

  public override func removeObject(forKey defaultName: String) {
    capturedRemoveObjectKeys.append(defaultName)
  }
}
