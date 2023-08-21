/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import XCTest

final class GateKeeperManagerTests: XCTestCase {

  let graphRequestFactory = TestGraphRequestFactory()
  let connection = TestGraphRequestConnection()
  let graphRequestConnectionFactory = TestGraphRequestConnectionFactory()
  let store = UserDefaultsSpy()
  let storeIdentifierPrefix = "com.facebook.sdk:GateKeepers"
  let settings = TestSettings()

  override func setUp() {
    super.setUp()

    graphRequestConnectionFactory.stubbedConnection = connection
    _GateKeeperManager.configure(
      settings: settings,
      graphRequestFactory: graphRequestFactory,
      graphRequestConnectionFactory: graphRequestConnectionFactory,
      store: store
    )
  }

  override func tearDown() {
    super.tearDown()

    settings.reset()
    _GateKeeperManager.reset()
  }

  // MARK: - Dependencies

  func testDefaultDependencies() {
    _GateKeeperManager.reset()

    XCTAssertNil(
      _GateKeeperManager.graphRequestFactory,
      "Should not have a graph request factory by default"
    )
    XCTAssertNil(
      _GateKeeperManager.graphRequestConnectionFactory,
      "Should not have a graph request connection factory by default"
    )
    XCTAssertNil(
      _GateKeeperManager.settings,
      "Should not have settings by default"
    )
    XCTAssertNil(
      _GateKeeperManager.store,
      "Should not have a data store by default"
    )
  }

  func testConfiguringWithDependencies() {
    XCTAssertTrue(_GateKeeperManager.graphRequestFactory === graphRequestFactory)
    XCTAssertTrue(_GateKeeperManager.graphRequestConnectionFactory === graphRequestConnectionFactory)
    XCTAssertTrue(_GateKeeperManager.store === store)
  }

  // MARK: - Gatekeeper Validity

  func testValidityWithUnfinishedRequeryWithInvalidTimestamp() {
    _GateKeeperManager.requeryFinishedForAppStart = false
    _GateKeeperManager.timestamp = Date.distantPast

    XCTAssertFalse(
      _GateKeeperManager._gateKeeperIsValid(),
      "A gatekeeper with an unfinished requery and an invalid timestamp is not valid"
    )
  }

  func testValidityWithUnfinishedRequeryWithValidTimestamp() {
    _GateKeeperManager.requeryFinishedForAppStart = false
    _GateKeeperManager.timestamp = Date()

    XCTAssertFalse(
      _GateKeeperManager._gateKeeperIsValid(),
      "A gatekeeper with an unfinished requery and a valid timestamp is not valid"
    )
  }

  func testValidityWithFinishedRequeryWithInvalidTimestamp() {
    _GateKeeperManager.requeryFinishedForAppStart = true
    _GateKeeperManager.timestamp = Date.distantPast

    XCTAssertFalse(
      _GateKeeperManager._gateKeeperIsValid(),
      "A gatekeeper with a finished requery and an invalid timestamp is not valid"
    )
  }

  func testValidityWithFinishedRequeryWithValidTimestamp() {
    _GateKeeperManager.requeryFinishedForAppStart = true
    _GateKeeperManager.timestamp = Date()

    XCTAssertTrue(
      _GateKeeperManager._gateKeeperIsValid(),
      "A gatekeeper with a finished requery and a valid timestamp is valid"
    )
  }

  // MARK: - Loading Gatekeepers

  func testLoadingGateKeepersBeforeConfiguring() {
    _GateKeeperManager.reset()

    _GateKeeperManager.loadGateKeepers { _ in
      XCTFail("Should not invoke the completion when exiting early")
    }
  }

  func testLoadingGateKeepersWithoutAppIdWithoutCompletion() {
    settings.appID = nil
    _GateKeeperManager.gateKeepers = ["foo": "true"]
    _GateKeeperManager.loadGateKeepers(nil)
    XCTAssertNil(
      _GateKeeperManager.gateKeepers,
      "Should clear existing gatekeepers when trying to load without an app id"
    )
  }

  func testLoadingGateKeepersWithoutAppIdWithCompletion() {
    var didInvokeCompletion = false
    _GateKeeperManager.loadGateKeepers { potentialError in
      XCTAssertNil(
        potentialError,
        "Should complete without error if the app id is missing"
      )
      didInvokeCompletion = true
    }
    XCTAssertTrue(didInvokeCompletion)
  }

  func testLoadingGateKeepersWhenValid() {
    settings.appID = name
    updateGateKeeperValidity(isValid: true)

    var didInvokeCompletion = false
    _GateKeeperManager.loadGateKeepers { potentialError in
      XCTAssertNil(
        potentialError,
        "Should complete without error if the gatekeeper is valid"
      )
      didInvokeCompletion = true
    }
    XCTAssertTrue(didInvokeCompletion)
    XCTAssertNil(
      graphRequestFactory.capturedGraphPath,
      "Should not create a graph request if the gatekeeper is valid"
    )
    XCTAssertNil(
      connection.capturedRequest,
      "Should not create a graph connection if the gatekeeper is valid"
    )
  }

  func testLoadingGateKeepersWhenInvalidWhenNotCurrentlyLoading() {
    settings.appID = name
    _GateKeeperManager.gateKeepers = ["foo": "true"]
    updateGateKeeperValidity(isValid: false)

    _GateKeeperManager.loadGateKeepers { _ in
      XCTFail("Should not invoke completion")
    }
    XCTAssertTrue(_GateKeeperManager.isLoadingGateKeepers, "Should track when loading is in progress")
    validateGraphRequest(
      connection.capturedRequest,
      isEqualTo: _GateKeeperManager.requestToLoadGateKeepers()
    )
  }

  func testLoadingGateKeepersWhenInvalidWhenCurrentlyLoading() {
    settings.appID = name
    _GateKeeperManager.gateKeepers = ["foo": "true"]
    updateGateKeeperValidity(isValid: false)

    var completionCallCount = 0
    _GateKeeperManager.loadGateKeepers { _ in
      completionCallCount += 1
    }
    _GateKeeperManager.loadGateKeepers { _ in
      completionCallCount += 1
    }

    XCTAssertEqual(
      connection.startCallCount,
      1,
      "Should only start one connection even if there are multiple calls to load gatekeepers"
    )

    connection.capturedCompletion?(nil, nil, nil)

    XCTAssertEqual(completionCallCount, 2, "Should invoke all pending completions when the request finishes")
  }

  func testLoadingGateKeepersWithNonEmptyStore() throws {
    settings.appID = name

    let data = try NSKeyedArchiver.archivedData(
      withRootObject: SampleRawRemoteGatekeeper.validEnabled,
      requiringSecureCoding: true
    )
    store.setValue(data, forKey: storeIdentifierPrefix + name)

    _GateKeeperManager.loadGateKeepers(nil)

    XCTAssertEqual(
      _GateKeeperManager.gateKeepers as NSDictionary?,
      [
        "key": "foo",
        "value": true,
      ],
      "Loading gatekeepers should update local gatekeepers with those from the persistent store"
    )
  }

  // MARK: - Caching & Persistence

  func testUsesAppIdentifierForRetrieval() {
    settings.appID = name
    _GateKeeperManager.loadGateKeepers(nil)

    XCTAssertEqual(
      store.capturedObjectRetrievalKey,
      "com.facebook.sdk:GateKeepers\(name)",
      "Should use the app id in retrieving gatekeepers"
    )
  }

  func testInitialDataForCurrentAppIdentifier() {
    settings.appID = name
    _GateKeeperManager.loadGateKeepers(nil)

    XCTAssertNil(
      _GateKeeperManager.gateKeepers,
      "Should not have gatekeepers for the current app identifier by default"
    )
  }

  // MARK: - Request Creation

  func testCreatingRequest() {
    let appIdentifier = "foo"
    let version = "bar"
    settings.appID = appIdentifier
    settings.sdkVersion = version
    _ = _GateKeeperManager.requestToLoadGateKeepers()

    XCTAssertEqual(
      graphRequestFactory.capturedGraphPath,
      "\(appIdentifier)/mobile_sdk_gk",
      "Should use the app identifier from the settings"
    )
    XCTAssertEqual(graphRequestFactory.capturedParameters?["platform"] as? String, "ios")
    XCTAssertEqual(
      graphRequestFactory.capturedParameters?["sdk_version"] as? String,
      version,
      "Should use the sdk version from the settings"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedParameters?["fields"] as? String,
      "gatekeepers",
      "Should request the expected fields"
    )
    XCTAssertNil(
      graphRequestFactory.capturedTokenString,
      "The gate keepers request should be tokenless"
    )
    XCTAssertNil(
      graphRequestFactory.capturedHTTPMethod,
      "Should not provide an explicit http method"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedFlags,
      [GraphRequestFlags.skipClientToken, GraphRequestFlags.disableErrorRecovery],
      "Should provide the expected graph request flags"
    )
  }

  // MARK: - Parsing Results

  func testParsingResponseFinishesFetch() {
    _GateKeeperManager.isLoadingGateKeepers = true
    _GateKeeperManager.parse(result: nil, error: nil)
    XCTAssertFalse(
      _GateKeeperManager.isLoadingGateKeepers,
      "Parsing the response should indicate that the fetch is completed"
    )
  }

  func testParsingWithError() {
    settings.appID = name
    updateGateKeeperValidity(isValid: false)
    let error = SampleError() as NSError

    _GateKeeperManager.loadGateKeepers { potentialError in
      XCTAssertEqual(potentialError as NSError?, error, "Should complete with any errors from parsing")
    }

    _GateKeeperManager.parse(result: nil, error: error)
  }

  func testParsingWithMissingGateKeepers() {
    _GateKeeperManager.parse(result: SampleRawRemoteGatekeeperList.missingGatekeepers, error: nil)

    XCTAssertNil(
      _GateKeeperManager.gateKeepers,
      "Should not parse gatekeepers from a response missing the gatekeepers key"
    )
  }

  func testParsingWithEmptyGateKeepers() {
    _GateKeeperManager.parse(result: SampleRawRemoteGatekeeperList.emptyGatekeepers, error: nil)

    XCTAssertEqual(
      _GateKeeperManager.gateKeepers as NSDictionary?,
      [:],
      "Should not parse gatekeepers from an empty list"
    )
  }

  func testParsingWithValidGateKeepers() {
    _GateKeeperManager.parse(
      result: SampleRawRemoteGatekeeperList.validHeterogeneous,
      error: nil
    )

    let expected = [
      "foo": true,
      "bar": false,
    ] as NSDictionary

    XCTAssertEqual(
      _GateKeeperManager.gateKeepers as NSDictionary?,
      expected,
      "Should parse gatekeepers from a valid response"
    )
  }

  func testParsingWithValidGateKeepersCaches() {
    settings.appID = name
    _GateKeeperManager.parse(
      result: SampleRawRemoteGatekeeperList.validHeterogeneous,
      error: nil
    )

    XCTAssertEqual(
      store.capturedSetObjectKey,
      "com.facebook.sdk:GateKeepers\(name)",
      "Should use the app id in persisting the gatekeepers"
    )
  }

  func testParsingWithRandomizedResults() {
    (1 ... 100).forEach { _ in
      let result = Fuzzer.randomize(json: SampleRawRemoteGatekeeperList.valid)
      _GateKeeperManager.parse(result: result, error: nil)
    }
  }

  // MARK: - Retrieval

  func testRetrievingWithMissingAppID() {
    _GateKeeperManager.gateKeepers = [name: false]
    _GateKeeperManager.bool(forKey: name, defaultValue: true)

    XCTAssertNil(
      _GateKeeperManager.gateKeepers,
      "Retrieving gatekeepers without an app id should remove the stored gatekeepers"
    )
  }

  func testRetrievingGateKeeperTriggersLoading() {
    settings.appID = name
    _GateKeeperManager.bool(forKey: "foo", defaultValue: false)
    XCTAssertNotNil(
      store.capturedObjectRetrievalKey,
      "Retrieving a gatekeeper should load gatekeepers"
    )
  }

  func testRetrievingMissingGateKeeper() {
    settings.appID = name
    XCTAssertTrue(_GateKeeperManager.bool(forKey: name, defaultValue: true))
    XCTAssertFalse(_GateKeeperManager.bool(forKey: name, defaultValue: false))

    settings.appID = nil
    XCTAssertTrue(_GateKeeperManager.bool(forKey: name, defaultValue: true))
    XCTAssertFalse(_GateKeeperManager.bool(forKey: name, defaultValue: false))
  }

  func testRetrievingGateKeeperWithAppID() {
    settings.appID = name
    _GateKeeperManager.gateKeepers = [name: false]
    XCTAssertFalse(
      _GateKeeperManager.bool(forKey: name, defaultValue: true),
      "Should return the stored gatekeeper value for the matching key and ignore the default value"
    )
  }

  // MARK: - Helpers

  func updateGateKeeperValidity(isValid: Bool) {
    if isValid {
      _GateKeeperManager.requeryFinishedForAppStart = true
      _GateKeeperManager.timestamp = Date()
    } else {
      _GateKeeperManager.requeryFinishedForAppStart = false
      _GateKeeperManager.timestamp = Date.distantPast
    }
  }

  func validateGraphRequest(
    _ potentialRequest: GraphRequestProtocol?,
    isEqualTo potentialOtherRequest: GraphRequestProtocol?,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    guard let request = potentialRequest else {
      return XCTFail("First request must not be nil", file: file, line: line)
    }
    guard let otherRequest = potentialOtherRequest else {
      return XCTFail("Second request must not be nil", file: file, line: line)
    }
    XCTAssertEqual(request.graphPath, otherRequest.graphPath, "Graph paths should be equal", file: file, line: line)
    XCTAssertEqual(request.version, otherRequest.version, "Versions should be equal", file: file, line: line)
    XCTAssertEqual(request.httpMethod, otherRequest.httpMethod, "HTTP methods should be equal", file: file, line: line)
    let parameters = request.parameters as NSDictionary
    let otherParameters = otherRequest.parameters as NSDictionary
    XCTAssertEqual(parameters, otherParameters, "Parameters should be equal", file: file, line: line)
    XCTAssertEqual(
      request.tokenString,
      otherRequest.tokenString,
      "Token strings should be equal",
      file: file,
      line: line
    )
  }
}
