/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import Foundation

final class TestDataStore: DataPersisting {

  var stubbedError: LocalStorageError?
  var stubbedUserSessionData: Data?
  var isReadCalled = false
  var isSaveCalled = false
  var isDeleteCalled = false
  var capturedDataInAdd: Data?

  func save(_ data: Data) throws {
    isSaveCalled = true
    capturedDataInAdd = data
    if let error = stubbedError {
      throw error
    }
  }

  func read() throws -> Data {
    isReadCalled = true
    if let error = stubbedError {
      throw error
    }
    if let data = stubbedUserSessionData {
      return data
    } else {
      throw LocalStorageError.itemNotFound
    }
  }

  func delete() throws {
    isDeleteCalled = true
    if let error = stubbedError {
      throw error
    }
  }
}
