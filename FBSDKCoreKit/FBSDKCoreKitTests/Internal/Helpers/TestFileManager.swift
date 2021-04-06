// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FBSDKCoreKit
import XCTest

import Foundation

class TestFileManager: FileManaging {
  var removeItemAtPathWasCalled = false
  var contentsOfDirectoryAtPathWasCalled = false
  var capturedFileExistsAtPath: String?
  var capturedCreateDirectoryPath: String?
  var stubbedContentsOfDirectory = [String]()
  var stubbedFileExists = true
  var stubbedCreateDirectoryShouldSucceed = true

  let tempDirectoryURL: URL

  init(tempDirectoryURL: URL) {
    self.tempDirectoryURL = tempDirectoryURL
  }

  func url(
    for directory: FileManager.SearchPathDirectory,
    in domain: FileManager.SearchPathDomainMask,
    appropriateFor url: URL,
    create shouldCreate: Bool
    ) throws -> URL {
    return tempDirectoryURL
  }

  func createDirectory(
    atPath path: String,
    withIntermediateDirectories createIntermediates: Bool,
    attributes: [FileAttributeKey: Any]? = [:]
  ) throws {
    capturedCreateDirectoryPath = path
    if !stubbedCreateDirectoryShouldSucceed {
      throw SampleError()
    }
  }

  func fileExists(atPath path: String) -> Bool {
    capturedFileExistsAtPath = path
    return stubbedFileExists
  }

  func contentsOfDirectory(atPath path: String, error: NSErrorPointer) -> [String] {
    contentsOfDirectoryAtPathWasCalled = true

    return stubbedContentsOfDirectory
  }

  func removeItem(atPath path: String) throws {
    removeItemAtPathWasCalled = true
  }
}
