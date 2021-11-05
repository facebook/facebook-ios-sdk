/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class TestDataStore: DataPersisting {
  func setInteger(_ value: Int, forKey defaultName: String) {}
  func setObject(_ value: Any, forKey defaultName: String) {}
  func data(forKey defaultName: String) -> Data? { nil }
  func integer(forKey defaultName: String) -> Int { Int.min }
  func string(forKey defaultName: String) -> String? { nil }
  func object(forKey defaultName: String) -> Any? { nil }
  func removeObject(forKey defaultName: String) {}
}
