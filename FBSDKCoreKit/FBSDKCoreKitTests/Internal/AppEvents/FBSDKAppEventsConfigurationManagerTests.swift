/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools

class FBSDKAppEventsConfigurationManagerTests: XCTestCase {

  let store = UserDefaultsSpy()
  let settings = TestSettings()
  let graphRequestFactory = TestGraphRequestFactory()
  let connection = TestGraphRequestConnection()
  lazy var graphRequestConnectionFactory = TestGraphRequestConnectionFactory.create(withStubbedConnection: connection)
  let timestampKey = "com.facebook.sdk:FBSDKAppEventsConfigurationTimestamp"

  override class func setUp() {
    super.setUp()

    AppEventsConfigurationManager.reset()
  }

  override func setUp() {
    super.setUp()

    settings.appID = name

    AppEventsConfigurationManager.configure(
      store: store,
      settings: settings,
      graphRequestFactory: graphRequestFactory,
      graphRequestConnectionFactory: graphRequestConnectionFactory
    )
  }

  override func tearDown() {
    super.tearDown()

    AppEventsConfigurationManager.reset()
  }

  // MARK: - Dependencies

  func testDefaultDependencies() {
    AppEventsConfigurationManager.reset()

    XCTAssertNil(
      AppEventsConfigurationManager.shared.store,
      "Should not have a data store by default"
    )
    XCTAssertNil(
      AppEventsConfigurationManager.shared.settings,
      "Should not have a settings by default"
    )
    XCTAssertNil(
      AppEventsConfigurationManager.shared.graphRequestFactory,
      "Should not have a graph request factory by default"
    )
    XCTAssertNil(
      AppEventsConfigurationManager.shared.graphRequestConnectionFactory,
      "Should not have a graph request connection factory by default"
    )
  }

  func testConfiguringWithDependencies() {
    XCTAssertTrue(
      AppEventsConfigurationManager.shared.store === store,
      "Should be able to configure with a persistent data store"
    )
    XCTAssertEqual(
      AppEventsConfigurationManager.shared.settings as? TestSettings,
      settings,
      "Should be able to configure with custom settings"
    )
    XCTAssertEqual(
      AppEventsConfigurationManager.shared.graphRequestFactory as? TestGraphRequestFactory,
      graphRequestFactory,
      "Should be able to configure with a custom graph request provider"
    )
    XCTAssertEqual(
      AppEventsConfigurationManager.shared.graphRequestConnectionFactory as? TestGraphRequestConnectionFactory,
      graphRequestConnectionFactory,
      "Should be able to configure with a custom graph request connection provider"
    )
  }

  func testConfiguringSetsTimestamp() {
    store.set(Date.distantPast, forKey: timestampKey)
    AppEventsConfigurationManager.configure(
      store: store,
      settings: settings,
      graphRequestFactory: graphRequestFactory,
      graphRequestConnectionFactory: graphRequestConnectionFactory
    )

    XCTAssertEqual(
      AppEventsConfigurationManager.shared.timestamp,
      .distantPast,
      "Should set the timestamp to the value in the provided store"
    )
  }

  // MARK: - Parsing

  func testParsingResponses() {
    for _ in 0..<100 {
      AppEventsConfigurationManager.shared._processResponse(
        RawAppEventsConfigurationResponseFixtures.random,
        error: nil
      )
    }
  }

  // MARK: - Loading Configuration

  func testLoadConfigurationRequest() {
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {}

    XCTAssertEqual(
      graphRequestFactory.capturedGraphPath,
      name,
      "Should create a request with the expected path"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedParameters as? [String: String],
      ["fields": "app_events_config.os_version(\(UIDevice.current.systemVersion))"],
      "Should create a request with the expected parameters"
    )
    XCTAssertNil(
      graphRequestFactory.capturedTokenString,
      "Should not include a token string in the request"
    )
    XCTAssertNil(
      graphRequestFactory.capturedHttpMethod,
      "Should not specify an http method when creating the request"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedFlags,
      [],
      "Should not specify flags when creating the request"
    )
  }

  func testLoadingConfigurationWithoutAppID() {
    settings.appID = nil
    var didInvokeCompletion = false
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {
      didInvokeCompletion = true
    }

    XCTAssertNil(
      graphRequestFactory.capturedGraphPath,
      "Should not create a graph request when there is no app id available"
    )
    XCTAssertTrue(
      didInvokeCompletion,
      "Should invoke the completion when failing to load a request"
    )
  }

  func testEarlyExitFromLoadingInvokesAndClearsPendingCompletions() {
    var firstCompletionCallCount = 0
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {
      firstCompletionCallCount += 1
    }
    var secondCompletionCallCount = 0
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {
      secondCompletionCallCount += 1
    }

    settings.appID = nil
    var thirdCompletionCallCount = 0
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {
      thirdCompletionCallCount += 1
    }

    XCTAssertEqual(firstCompletionCallCount, 1)
    XCTAssertEqual(secondCompletionCallCount, 1)
    XCTAssertEqual(thirdCompletionCallCount, 1)
    XCTAssertNotNil(
      connection.capturedRequest,
      "Should probably cancel any ongoing tasks but currently does not"
    )
  }

  func testCompletingFetchInvokesPendingCompletionHandlers() {
    var firstCompletionCallCount = 0
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {
      firstCompletionCallCount += 1
    }
    var secondCompletionCallCount = 0
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {
      secondCompletionCallCount += 1
    }

    connection.capturedCompletion?(nil, RawAppEventsConfigurationResponseFixtures.valid, nil)

    XCTAssertEqual(firstCompletionCallCount, 1)
    XCTAssertEqual(secondCompletionCallCount, 1)
  }

  func testCompletingFetchClearsPendingCompletionHandlers() {
    var firstCompletionCallCount = 0
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {
      firstCompletionCallCount += 1
    }
    var secondCompletionCallCount = 0
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {
      secondCompletionCallCount += 1
    }

    connection.capturedCompletion?(nil, RawAppEventsConfigurationResponseFixtures.valid, nil)

    // Fetch without app id to early exit and invoke any pending completions
    settings.appID = nil
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {}

    XCTAssertEqual(firstCompletionCallCount, 1)
    XCTAssertEqual(secondCompletionCallCount, 1)
  }

  func testLoadingWhileLoadingInProgress() {
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {}
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {}

    XCTAssertEqual(
      connection.startCallCount,
      1,
      "Should not start a request while a request is in progress"
    )

    connection.capturedCompletion?(nil, RawAppEventsConfigurationResponseFixtures.valid, nil)

    // Otherwise it won't try to fetch again so we cannot test that the
    // isLoading lock is reset.
    AppEventsConfigurationManager.shared.hasRequeryFinishedForAppStart = false

    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {}

    XCTAssertEqual(
      connection.startCallCount,
      2,
      "Should start a request if no request is in progress"
    )
  }

  func testLoadingWithFinishedRequeryAndValidTimestamp() {
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {}
    connection.capturedCompletion?(nil, RawAppEventsConfigurationResponseFixtures.valid, nil)

    var completionCallCount = 0
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {
      completionCallCount += 1
    }

    XCTAssertEqual(
      completionCallCount,
      1,
      "Should exit early if a fetch has finished for the session and the timestamp is valid"
    )
  }

  func testLoadingWithFinishedRequeryAndInvalidTimestamp() {
    AppEventsConfigurationManager.shared.hasRequeryFinishedForAppStart = true
    AppEventsConfigurationManager.shared.timestamp = .distantPast

    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {}

    XCTAssertEqual(
      connection.startCallCount,
      1,
      "Should fetch the configuration if the requery has finished but the timestamp is invalid"
    )
  }

  func testCompleteLoadingWithError() {
    var firstCompletionCallCount = 0
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {
      firstCompletionCallCount += 1
    }
    connection.capturedCompletion?(nil, nil, SampleError())

    XCTAssertTrue(
      AppEventsConfigurationManager.shared.hasRequeryFinishedForAppStart,
      "Completing with an error should indicate that the fetch completed"
    )
    XCTAssertNil(
      AppEventsConfigurationManager.shared.timestamp,
      "Completing with an error should not set a timestamp"
    )
    XCTAssertEqual(
      firstCompletionCallCount,
      1,
      "Completions should be called due to the error so as to not block the main thread."
    )
  }

  func testCompleteLoadingWithoutAppIDClearsExistingCompletions() {
    var firstCompletionCallCount = 0
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {
      firstCompletionCallCount += 1
    }
    var secondCompletionCallCount = 0
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {
      secondCompletionCallCount += 1
    }

    // Fetch without app id to early exit and invoke any pending completions
    settings.appID = nil
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {}

    XCTAssertEqual(firstCompletionCallCount, 1)
    XCTAssertEqual(secondCompletionCallCount, 1)
  }

  func testUnarchivesStoredCaptureEvents() {
    // Validates unarchival from store
    AppEventsConfigurationManager.shared.loadAppEventsConfiguration {}

    // Confirm default state
    XCTAssertTrue(AppEventsConfigurationManager.shared.cachedAppEventsConfiguration.advertiserIDCollectionEnabled)
    XCTAssertFalse(AppEventsConfigurationManager.shared.cachedAppEventsConfiguration.eventCollectionEnabled)
    // Capture inverted configurations
    connection.capturedCompletion?(nil, RawAppEventsConfigurationResponseFixtures.valid, nil)
    // Copy store state to avoid meaningless test
    let storeCopy = UserDefaultsSpy()
    let storeDump = store.dictionaryRepresentation()
    storeDump.keys.forEach {
      if $0.hasPrefix("com.facebook") {
        storeCopy.setValue(storeDump[$0], forKey: $0)
      }
    }
    storeCopy.capturedObjectRetrievalKey = store.capturedObjectRetrievalKey
    storeCopy.capturedSetObjectKey = store.capturedSetObjectKey
    storeCopy.capturedValues = store.capturedValues
    // Configure shared manager with copied store state
    AppEventsConfigurationManager.configure(
      store: storeCopy,
      settings: settings,
      graphRequestFactory: graphRequestFactory,
      graphRequestConnectionFactory: graphRequestConnectionFactory
    )
    // Confirm configuration is unarchived from store instead of set again from defaults
    XCTAssertFalse(AppEventsConfigurationManager.shared.cachedAppEventsConfiguration.advertiserIDCollectionEnabled)
    XCTAssertTrue(AppEventsConfigurationManager.shared.cachedAppEventsConfiguration.eventCollectionEnabled)
  }
}
