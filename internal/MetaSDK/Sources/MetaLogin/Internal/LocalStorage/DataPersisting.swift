/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

protocol DataPersisting {
    func integer(forKey defaultName: String) -> Int
    func set(_ value: Int, forKey defaultName: String)
    func removeObject(forKey: String)
}

extension UserDefaults: DataPersisting {}
