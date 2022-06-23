/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class TestDataStore: DataPersisting {
  func fb_setInteger(_ value: Int, forKey defaultName: String) {}
  func fb_setObject(_ value: Any, forKey defaultName: String) {}
  func fb_data(forKey defaultName: String) -> Data? { nil }
  func fb_integer(forKey defaultName: String) -> Int { Int.min }
  func fb_string(forKey defaultName: String) -> String? { nil }
  func fb_object(forKey defaultName: String) -> Any? { nil }
  func fb_removeObject(forKey defaultName: String) {}
}
