/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class TestDataStorage: DataPersisting {
    var capturedIntegerForKeyName: String?
    var stubbedIntegerForKey = 0
    var capturedSetIntegerForKeyName: String?
    var capturedRemoveStringForKeyName: String?
    var capturedSetIntValue: Int?

    func integer(forKey defaultName: String) -> Int {
        capturedIntegerForKeyName = defaultName
        return stubbedIntegerForKey
    }

    func set(_ value: Int, forKey defaultName: String) {
        capturedSetIntegerForKeyName = defaultName
        capturedSetIntValue = value
    }

    func removeObject(forKey: String) {
        capturedRemoveStringForKeyName = forKey
    }
}
