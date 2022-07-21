// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

protocol DataPersisting {
    func integer(forKey defaultName: String) -> Int
    func set(_ value: Int, forKey defaultName: String)
}

extension UserDefaults: DataPersisting {}
