/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class UserDefaultsStore: KeyedValueMapping {

  private let userDefaults = UserDefaults.standard

  func getIntegerValue(for key: String) -> Int? {
    if userDefaults.bool(forKey: key) {
      return userDefaults.integer(forKey: key)
    } else {
      return nil
    }
  }

  func set(_ value: Int, for key: String) {
    userDefaults.set(value, forKey: key)
  }

  func remove(for key: String) {
    userDefaults.removeObject(forKey: key)
  }
}
