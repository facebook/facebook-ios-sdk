/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

final class ModelManagerTests: XCTestCase {

  let manager = ModelManager.shared
  let featureChecker = TestFeatureManager()
  let factory = TestGraphRequestFactory()
  let modelDirectoryPath = "\(NSTemporaryDirectory())models"
  lazy var fileManager = TestFileManager(tempDirectoryURL: SampleURLs.valid)
  let store = UserDefaultsSpy()
  let settings = TestSettings()
  let suggestedEventsIndexer = TestSuggestedEventsIndexer()

  enum Keys {
    static let modelInfoPersistence = "com.facebook.sdk:FBSDKModelInfo"
    static let modelTimestampPersistence = "com.facebook.sdk:FBSDKModelRequestTimestamp"
  }

  override class func setUp() {
    super.setUp()

    ModelManager.reset()
    TestGateKeeperManager.reset()
  }

  override func setUp() {
    super.setUp()

    settings.appID = name
    manager.configure(
      withFeatureChecker: featureChecker,
      graphRequestFactory: factory,
      fileManager: fileManager,
      store: store,
      settings: settings,
      dataExtractor: TestFileDataExtractor.self,
      gateKeeperManager: TestGateKeeperManager.self,
      suggestedEventsIndexer: suggestedEventsIndexer,
      featureExtractor: TestFeatureExtractor.self
    )
  }

  override func tearDown() {
    ModelManager.reset()
    TestFileDataExtractor.reset()
    TestGateKeeperManager.reset()
    TestFeatureExtractor.reset()

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

  func testEnablingRetrievesCache() {
    manager.enable()

    let keys = store.capturedObjectRetrievalKeys

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

  // MARK: - Getting Rules

  func testGettingRulesForKeyWithMissingModelInfo() {
    ModelManager.directoryPath = "foo"

    XCTAssertNil(
      manager.getRulesForKey(RawRemoteModelResponse.UseCase.detection),
      "Should not get rules when there are no models"
    )
  }

  func testGettingRulesForKeyWithMismatchedKey() {
    ModelManager.directoryPath = "foo"
    ModelManager.setModelInfo(RemoteModelResponse.valid)

    XCTAssertNil(
      manager.getRulesForKey(RawRemoteModelResponse.UseCase.missing),
      "Should not get rules when the key does not match any of the stored models."
    )
  }

  func testGettingRulesForKeyWithMatchingKeyWithMissingData() throws {
    ModelManager.directoryPath = "foo"
    ModelManager.setModelInfo(RemoteModelResponse.valid)

    XCTAssertNil(
      manager.getRulesForKey(RawRemoteModelResponse.UseCase.detection),
      "Should not return rules when the data is missing"
    )
  }

  func testGettingRulesForKeyWithMatchingKeyWithInvalidData() throws {
    ModelManager.directoryPath = "foo"
    ModelManager.setModelInfo(RemoteModelResponse.valid)

    TestFileDataExtractor.stubbedData = name.data(using: .utf8)

    XCTAssertNil(
      manager.getRulesForKey(RawRemoteModelResponse.UseCase.detection),
      "Should not return rules when the data cannot be deserialized into a dictionary"
    )

    XCTAssertEqual(
      TestFileDataExtractor.capturedFileNames.first,
      "foo/\(RawRemoteModelResponse.UseCase.detection)_1.rules",
      "Should read data from the file name matching the use case"
    )
  }

  func testGettingRulesForKeyWithMatchingKeyWithValidData() throws {
    ModelManager.directoryPath = "foo"
    ModelManager.setModelInfo(RemoteModelResponse.valid)

    TestFileDataExtractor.stubbedData = try JSONSerialization.data(
      withJSONObject: RawRemoteModelResponse.detectionAsset,
      options: []
    )

    XCTAssertNotNil(
      manager.getRulesForKey(RawRemoteModelResponse.UseCase.detection),
      "Should return rules when the data can be deserialized"
    )

    XCTAssertEqual(
      TestFileDataExtractor.capturedFileNames.first,
      "foo/\(RawRemoteModelResponse.UseCase.detection)_1.rules",
      "Should read data from the file name matching the use case"
    )
  }

  // MARK: - Mappings

  func testIntegrityMapping() {
    XCTAssertEqual(
      ModelManager.getIntegrityMapping(),
      ["none", "address", "health"]
    )
  }

  func testSuggestedEventsMapping() {
    XCTAssertEqual(
      ModelManager.getSuggestedEventsMapping(),
      [
        "other",
        "fb_mobile_complete_registration",
        "fb_mobile_add_to_cart",
        "fb_mobile_purchase",
        "fb_mobile_initiated_checkout",
      ]
    )
  }
}

// The production code restructures the raw response slightly to make
// it a little more usable. This just captures that structure so it
// can be used in methods that expect this format.
private enum RemoteModelResponse {
  static let valid: [String: Any] = [
    RawRemoteModelResponse.UseCase.eventPrediction: RawRemoteModelResponse.eventPredictionAsset,
    RawRemoteModelResponse.UseCase.detection: RawRemoteModelResponse.detectionAsset,
  ]
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
    static let missing = "missing"
  }

  static let valid: [String: Any] = [Keys.data: validAssets]
  static let invalid: [String: Any] = [
    Keys.data: [
      [
        Keys.assetURI: nil,
        Keys.useCase: UseCase.eventPrediction,
      ],
    ],
  ]

  static let eventPredictionAsset: [String: Any] = [
    Keys.assetURI: SampleURLs.valid(path: "asset1").absoluteString,
    Keys.rulesURI: SampleURLs.valid(path: "rules1").absoluteString,
    Keys.thresholds: [
      1,
      "0.68",
      "0.7",
      "0.5",
      "0.84",
    ],
    Keys.useCase: UseCase.eventPrediction,
    Keys.versionID: 4,
  ]

  static let detectionAsset: [String: Any] = [
    Keys.assetURI: SampleURLs.valid(path: "asset2").absoluteString,
    Keys.thresholds: [
      1,
      "0.85",
      "0.6",
    ],
    Keys.useCase: UseCase.detection,
    Keys.versionID: 1,
  ]

  static let validAssets: [[String: Any]] = [
    eventPredictionAsset,
    detectionAsset,
  ]
}
