/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools

final class AppEventsConfigurationManagerTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var manager: AppEventsConfigurationManager!
  var store: UserDefaultsSpy!
  var settings: TestSettings!
  var graphRequestFactory: TestGraphRequestFactory!
  var connection: TestGraphRequestConnection!
  var graphRequestConnectionFactory: TestGraphRequestConnectionFactory!
  let timestampKey = "com.facebook.sdk:FBSDKAppEventsConfigurationTimestamp"
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    store = UserDefaultsSpy()
    settings = TestSettings()
    settings.appID = name
    graphRequestFactory = TestGraphRequestFactory()
    connection = TestGraphRequestConnection()
    graphRequestConnectionFactory = TestGraphRequestConnectionFactory.create(withStubbedConnection: connection)

    manager = AppEventsConfigurationManager()
    manager.configure(
      store: store,
      settings: settings,
      graphRequestFactory: graphRequestFactory,
      graphRequestConnectionFactory: graphRequestConnectionFactory
    )
  }

  override func tearDown() {
    super.tearDown()

    store = nil
    settings = nil
    graphRequestFactory = nil
    connection = nil
    manager = nil
  }

  // MARK: - Dependencies

  func testDefaultDependencies() {
    manager.resetDependencies()

    XCTAssertNil(
      manager.store,
      "Should not have a data store by default"
    )
    XCTAssertNil(
      manager.settings,
      "Should not have a settings by default"
    )
    XCTAssertNil(
      manager.graphRequestFactory,
      "Should not have a graph request factory by default"
    )
    XCTAssertNil(
      manager.graphRequestConnectionFactory,
      "Should not have a graph request connection factory by default"
    )
  }

  func testConfiguringWithDependencies() {
    XCTAssertTrue(
      manager.store === store,
      "Should be able to configure with a persistent data store"
    )
    XCTAssertEqual(
      manager.settings as? TestSettings,
      settings,
      "Should be able to configure with custom settings"
    )
    XCTAssertEqual(
      manager.graphRequestFactory as? TestGraphRequestFactory,
      graphRequestFactory,
      "Should be able to configure with a custom graph request provider"
    )
    XCTAssertEqual(
      manager.graphRequestConnectionFactory as? TestGraphRequestConnectionFactory,
      graphRequestConnectionFactory,
      "Should be able to configure with a custom graph request connection provider"
    )
  }

  func testConfiguringSetsTimestamp() {
    store.set(Date.distantPast, forKey: timestampKey)
    manager.configure(
      store: store,
      settings: settings,
      graphRequestFactory: graphRequestFactory,
      graphRequestConnectionFactory: graphRequestConnectionFactory
    )

    XCTAssertEqual(
      manager.timestamp,
      .distantPast,
      "Should set the timestamp to the value in the provided store"
    )
  }

  // MARK: - Parsing

  func testParsingResponses() {
    for _ in 0 ..< 100 {
      manager._processResponse(
        RawAppEventsConfigurationResponseFixtures.random,
        error: nil
      )
    }
  }

  // MARK: - Loading Configuration

  func testLoadConfigurationRequest() {
    manager.loadAppEventsConfiguration {}

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
    manager.loadAppEventsConfiguration {
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
    manager.loadAppEventsConfiguration {
      firstCompletionCallCount += 1
    }
    var secondCompletionCallCount = 0
    manager.loadAppEventsConfiguration {
      secondCompletionCallCount += 1
    }

    settings.appID = nil
    var thirdCompletionCallCount = 0
    manager.loadAppEventsConfiguration {
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
    manager.loadAppEventsConfiguration {
      firstCompletionCallCount += 1
    }
    var secondCompletionCallCount = 0
    manager.loadAppEventsConfiguration {
      secondCompletionCallCount += 1
    }

    connection.capturedCompletion?(nil, RawAppEventsConfigurationResponseFixtures.valid, nil)

    XCTAssertEqual(firstCompletionCallCount, 1)
    XCTAssertEqual(secondCompletionCallCount, 1)
  }

  func testCompletingFetchClearsPendingCompletionHandlers() {
    var firstCompletionCallCount = 0
    manager.loadAppEventsConfiguration {
      firstCompletionCallCount += 1
    }
    var secondCompletionCallCount = 0
    manager.loadAppEventsConfiguration {
      secondCompletionCallCount += 1
    }

    connection.capturedCompletion?(nil, RawAppEventsConfigurationResponseFixtures.valid, nil)

    // Fetch without app id to early exit and invoke any pending completions
    settings.appID = nil
    manager.loadAppEventsConfiguration {}

    XCTAssertEqual(firstCompletionCallCount, 1)
    XCTAssertEqual(secondCompletionCallCount, 1)
  }

  func testLoadingWhileLoadingInProgress() {
    manager.loadAppEventsConfiguration {}
    manager.loadAppEventsConfiguration {}

    XCTAssertEqual(
      connection.startCallCount,
      1,
      "Should not start a request while a request is in progress"
    )

    connection.capturedCompletion?(nil, RawAppEventsConfigurationResponseFixtures.valid, nil)

    // Otherwise it won't try to fetch again so we cannot test that the
    // isLoading lock is reset.
    manager.hasRequeryFinishedForAppStart = false

    manager.loadAppEventsConfiguration {}

    XCTAssertEqual(
      connection.startCallCount,
      2,
      "Should start a request if no request is in progress"
    )
  }

  func testLoadingWithFinishedRequeryAndValidTimestamp() {
    manager.loadAppEventsConfiguration {}
    connection.capturedCompletion?(nil, RawAppEventsConfigurationResponseFixtures.valid, nil)

    var completionCallCount = 0
    manager.loadAppEventsConfiguration {
      completionCallCount += 1
    }

    XCTAssertEqual(
      completionCallCount,
      1,
      "Should exit early if a fetch has finished for the session and the timestamp is valid"
    )
  }

  func testLoadingWithFinishedRequeryAndInvalidTimestamp() {
    manager.hasRequeryFinishedForAppStart = true
    manager.timestamp = .distantPast

    manager.loadAppEventsConfiguration {}

    XCTAssertEqual(
      connection.startCallCount,
      1,
      "Should fetch the configuration if the requery has finished but the timestamp is invalid"
    )
  }

  func testCompleteLoadingWithError() {
    var firstCompletionCallCount = 0
    manager.loadAppEventsConfiguration {
      firstCompletionCallCount += 1
    }
    connection.capturedCompletion?(nil, nil, SampleError())

    XCTAssertTrue(
      manager.hasRequeryFinishedForAppStart,
      "Completing with an error should indicate that the fetch completed"
    )
    XCTAssertNil(
      manager.timestamp,
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
    manager.loadAppEventsConfiguration {
      firstCompletionCallCount += 1
    }
    var secondCompletionCallCount = 0
    manager.loadAppEventsConfiguration {
      secondCompletionCallCount += 1
    }

    // Fetch without app id to early exit and invoke any pending completions
    settings.appID = nil
    manager.loadAppEventsConfiguration {}

    XCTAssertEqual(firstCompletionCallCount, 1)
    XCTAssertEqual(secondCompletionCallCount, 1)
  }

  func testUnarchivesStoredCaptureEvents() {
    // Validates unarchival from store
    manager.loadAppEventsConfiguration {}

    // Confirm default state
    XCTAssertTrue(manager.cachedAppEventsConfiguration.advertiserIDCollectionEnabled)
    XCTAssertFalse(manager.cachedAppEventsConfiguration.eventCollectionEnabled)

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
    manager.configure(
      store: storeCopy,
      settings: settings,
      graphRequestFactory: graphRequestFactory,
      graphRequestConnectionFactory: graphRequestConnectionFactory
    )

    // Confirm configuration is unarchived from store instead of set again from defaults
    XCTAssertFalse(manager.cachedAppEventsConfiguration.advertiserIDCollectionEnabled)
    XCTAssertTrue(manager.cachedAppEventsConfiguration.eventCollectionEnabled)
  }
}
