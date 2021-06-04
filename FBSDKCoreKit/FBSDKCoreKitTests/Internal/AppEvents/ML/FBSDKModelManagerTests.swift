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

import XCTest

class FBSDKModelManagerTests: XCTestCase {

  let manager = ModelManager()
  let featureChecker = TestFeatureManager()
  let factory = TestGraphRequestFactory()
  let modelDirectoryPath = "\(NSTemporaryDirectory())models"
  lazy var fileManager = TestFileManager(tempDirectoryURL: SampleUrls.valid)

  override class func setUp() {
    super.setUp()

    // Used to reset the nonce for the `enable` method
    ModelManager.reset()
  }

  override func setUp() {
    super.setUp()

    manager.configure(
      withFeatureChecker: featureChecker,
      graphRequestFactory: factory,
      fileManager: fileManager
    )
  }

  override func tearDown() {
    ModelManager.reset()

    super.tearDown()
  }

  func testEnablingWithoutCachedModels() {
    fileManager.stubbedFileExists = false

    manager.enable()

    XCTAssertEqual(
      fileManager.capturedFileExistsAtPath,
      modelDirectoryPath,
      "Enabling should check if the models were previously persisted to disk"
    )
    XCTAssertEqual(
      fileManager.capturedCreateDirectoryPath,
      modelDirectoryPath,
      "Enabling should create a directory for caching models if one does not exist already"
    )
  }

  func testEnablingWithCachedModels() {
    manager.enable()

    XCTAssertEqual(
      fileManager.capturedFileExistsAtPath,
      modelDirectoryPath,
      "Enabling should check if the models were previously persisted to disk"
    )
    XCTAssertNil(
      fileManager.capturedCreateDirectoryPath,
      "Enabling should not create a directory for caching models if one exists already"
    )
  }

}
