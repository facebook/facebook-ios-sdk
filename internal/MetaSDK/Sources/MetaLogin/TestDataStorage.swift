// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

class TestDataStorage: DataPersisting {
    var capturedIntegerForKeyName: String?
    var stubbedIntegerForKey = 0
    var capturedSetIntegerForKeyName: String?
    var capturedSetValue: Int?
    
    func integer(forKey defaultName: String) -> Int {
        capturedIntegerForKeyName = defaultName
        return stubbedIntegerForKey
    }
    
    func set(_ value: Int, forKey defaultName: String) {
        capturedSetIntegerForKeyName = defaultName
        capturedSetValue = value
    }
}
