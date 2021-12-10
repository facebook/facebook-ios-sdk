/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class UserDefaultsSpy: UserDefaults {
  var capturedObjectRetrievalKeys = [String]()
  var capturedSetObjectKeys = [String]()
  var capturedObjectRetrievalKey: String?
  var capturedSetObjectKey: String?
  var capturedValues = [String: Any]()

  var stringForKeyCallback: ((String) -> String)? = { $0 }

  override func string(forKey defaultName: String) -> String? {
    stringForKeyCallback?(defaultName)
  }

  override func object(forKey defaultName: String) -> Any? {
    capturedObjectRetrievalKey = defaultName
    capturedObjectRetrievalKeys.append(defaultName)
    return capturedValues[defaultName]
  }

  override func set(_ value: Any?, forKey defaultName: String) {
    capturedValues[defaultName] = value
    capturedSetObjectKeys.append(defaultName)
    capturedSetObjectKey = defaultName
  }
}
