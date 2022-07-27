/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class TestKeychainStorage: KeychainPersisting {

    var stubbedSaveOSStatus: OSStatus = 0
    var stubbedReadOSStatus: OSStatus = 0
    var stubbedDeleteOSStatus: OSStatus = 0
    var stubbedUserSessionData: Data?
    var isReadCalled = false
    var isSaveCalled = false
    var isDeleteCalled = false
    var capturedDataInUpdate: Data?
    var capturedDataInAdd: Data?

    var keychainResult: KeychainResult {
        return KeychainResult(status: stubbedReadOSStatus, data: stubbedUserSessionData as Data?)
    }

    func save(data: Data) -> OSStatus {
        isSaveCalled = true
        capturedDataInAdd = data
        return stubbedSaveOSStatus
    }

    func read() -> KeychainResult {
        isReadCalled = true
        return keychainResult
    }

    func delete() -> OSStatus {
        isDeleteCalled = true
        return stubbedDeleteOSStatus
    }
}
