/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import Foundation

final class TestKeyedValueMap: KeyedValueMapping {
  var capturedIntegerKey: String?
  var stubbedIntegerForKey = 0
  var capturedSetIntegerForKeyName: String?
  var capturedRemoveStringForKeyName: String?
  var capturedSetIntValue: Int?

  func getIntegerValue(for key: String) -> Int? {
    capturedIntegerKey = key
    return stubbedIntegerForKey
  }

  func set(_ value: Int, for key: String) {
    capturedSetIntegerForKeyName = key
    capturedSetIntValue = value
  }

  func remove(for key: String) {
    capturedRemoveStringForKeyName = key
  }
}
