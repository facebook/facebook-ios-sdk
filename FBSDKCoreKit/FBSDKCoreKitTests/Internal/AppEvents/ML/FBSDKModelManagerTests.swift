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
  let store = UserDefaultsSpy()
  let settings = TestSettings()

  enum Keys {
    static let modelInfoPersistence = "com.facebook.sdk:FBSDKModelInfo"
    static let modelTimestampPersistence = "com.facebook.sdk:FBSDKModelRequestTimestamp"
  }

  override class func setUp() {
    super.setUp()

    ModelManager.reset()
  }

  override func setUp() {
    super.setUp()

    settings.appID = name
    manager.configure(
      withFeatureChecker: featureChecker,
      graphRequestFactory: factory,
      fileManager: fileManager,
      store: store,
      settings: settings
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

  func testEnablingRetrievesCache() throws {
    manager.enable()

    let keys = try XCTUnwrap(store.capturedObjectRetrievalKeys)

    XCTAssertTrue(
      keys.contains("com.facebook.sdk:FBSDKModelInfo"),
      "Enabling should retrieved cached model information"
    )
    XCTAssertTrue(
      keys.contains("com.facebook.sdk:FBSDKModelRequestTimestamp"),
      "Enabling should retrieved the timestamp of the last request"
    )
  }

  func testEnablingFetchesModelAssets() throws {
    manager.enable()

    let request = try XCTUnwrap(factory.capturedRequests.first)

    XCTAssertEqual(
      request.graphPath,
      "\(name)/model_asset",
      "Should create a request for model assets with the expected path"
    )
    XCTAssertEqual(
      request.startCallCount,
      1,
      "Should start the request to fetch model assets"
    )
  }

  func testCompletingModelAssetFetchWithError() throws {
    manager.enable()

    let completion = try XCTUnwrap(
      factory.capturedRequests.first?.capturedCompletionHandler
    )
    completion(nil, nil, SampleError())

    XCTAssertNil(
      store.capturedSetObjectKey,
      "Should not attempt to cache a model if there is an error in the response"
    )
  }

  func testCompletingModelAssetFetchWithEmptyResults() throws {
    manager.enable()

    let completion = try XCTUnwrap(
      factory.capturedRequests.first?.capturedCompletionHandler
    )
    completion(nil, [:], nil)

    XCTAssertNil(
      store.capturedSetObjectKey,
      "Should not attempt to cache a model if the result is empty"
    )
  }

  func testCompletingModelAssetFetchWithFuzzyResults() throws {
    manager.enable()

    let completion = try XCTUnwrap(
      factory.capturedRequests.first?.capturedCompletionHandler
    )

    (0 ... 100).forEach { _ in
      completion(nil, Fuzzer.randomize(json: RawRemoteModelResponse.valid), nil)
    }
  }

  func testCompletingModelAssetFetchWithInvalidResults() throws {
    manager.enable()

    let completion = try XCTUnwrap(
      factory.capturedRequests.first?.capturedCompletionHandler
    )
    completion(nil, RawRemoteModelResponse.invalid, nil)

    XCTAssertNil(
      store.capturedSetObjectKey,
      "Should not attempt to cache a model if the results are invalid"
    )
  }

  func testCompletingModelAssetFetchWithValidResults() throws {
    manager.enable()

    let completion = try XCTUnwrap(
      factory.capturedRequests.first?.capturedCompletionHandler
    )
    completion(nil, RawRemoteModelResponse.valid, nil)

    XCTAssertEqual(
      store.capturedSetObjectKeys,
      [Keys.modelInfoPersistence, Keys.modelTimestampPersistence],
      "Should attempt to cache info and creation time of model created from valid results"
    )
  }
}

private enum RawRemoteModelResponse {
  enum Keys {
    static let data = "data"
    static let assetURI = "asset_uri"
    static let rulesURI = "rules_uri"
    static let thresholds = "thresholds"
    static let useCase = "use_case"
    static let versionID = "version_id"
  }
  enum UseCase {
    static let eventPrediction = "MTML_APP_EVENT_PRED"
    static let detection = "MTML_INTEGRITY_DETECT"
  }

  static let valid: [String: Any] = [Keys.data: validAssets]
  static let invalid: [String: Any] = [
    Keys.data: [
      [
        Keys.assetURI: nil,
        Keys.useCase: UseCase.eventPrediction
      ]
    ]
  ]

  static let validAssets: [[String: Any]] = [
    [
      Keys.assetURI: SampleUrls.valid(path: "asset1").absoluteString,
      Keys.rulesURI: SampleUrls.valid(path: "rules1").absoluteString,
      Keys.thresholds: [
        1,
        "0.68",
        "0.7",
        "0.5",
        "0.84"
      ],
      Keys.useCase: UseCase.eventPrediction,
      Keys.versionID: 4
    ],
    [
      Keys.assetURI: SampleUrls.valid(path: "asset2").absoluteString,
      Keys.thresholds: [
        1,
        "0.85",
        "0.6"
      ],
      Keys.useCase: UseCase.detection,
      Keys.versionID: 1
    ]
  ]
}
