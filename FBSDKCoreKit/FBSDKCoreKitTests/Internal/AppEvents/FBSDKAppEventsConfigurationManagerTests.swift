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

import TestTools

// swiftlint:disable type_body_length
class FBSDKAppEventsConfigurationManagerTests: XCTestCase {

  let store = UserDefaultsSpy()
  let settings = TestSettings()
  let requestFactory = TestGraphRequestFactory()
  let connection = TestGraphRequestConnection()
  lazy var connectionFactory = TestGraphRequestConnectionFactory.create(withStubbedConnection: connection)
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
      graphRequestFactory: requestFactory,
      graphRequestConnectionFactory: connectionFactory
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
      AppEventsConfigurationManager.shared.requestFactory,
      "Should not have a graph request factory by default"
    )
    XCTAssertNil(
      AppEventsConfigurationManager.shared.connectionFactory,
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
      AppEventsConfigurationManager.shared.requestFactory as? TestGraphRequestFactory,
      requestFactory,
      "Should be able to configure with a custom graph request provider"
    )
    XCTAssertEqual(
      AppEventsConfigurationManager.shared.connectionFactory as? TestGraphRequestConnectionFactory,
      connectionFactory,
      "Should be able to configure with a custom graph request connection provider"
    )
  }

  func testConfiguringSetsTimestamp() {
    store.set(Date.distantPast, forKey: timestampKey)
    AppEventsConfigurationManager.configure(
      store: store,
      settings: settings,
      graphRequestFactory: requestFactory,
      graphRequestConnectionFactory: connectionFactory
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
      AppEventsConfigurationManager._processResponse(RawAppEventsConfigurationResponseFixtures.random, error: nil)
    }
  }

  // MARK: - Loading Configuration

  func testLoadConfigurationRequest() {
    AppEventsConfigurationManager.loadAppEventsConfiguration {}

    XCTAssertEqual(
      requestFactory.capturedGraphPath,
      name,
      "Should create a request with the expected path"
    )
    XCTAssertEqual(
      requestFactory.capturedParameters as? [String: String],
      ["fields": "app_events_config.os_version(\(UIDevice.current.systemVersion))"],
      "Should create a request with the expected parameters"
    )
    XCTAssertNil(
      requestFactory.capturedTokenString,
      "Should not include a token string in the request"
    )
    XCTAssertNil(
      requestFactory.capturedHttpMethod,
      "Should not specify an http method when creating the request"
    )
    XCTAssertEqual(
      requestFactory.capturedFlags,
      [],
      "Should not specify flags when creating the request"
    )
  }

  func testLoadingConfigurationWithoutAppID() {
    settings.appID = nil
    var didInvokeCompletion = false
    AppEventsConfigurationManager.loadAppEventsConfiguration {
      didInvokeCompletion = true
    }

    XCTAssertNil(
      requestFactory.capturedGraphPath,
      "Should not create a graph request when there is no app id available"
    )
    XCTAssertTrue(
      didInvokeCompletion,
      "Should invoke the completion when failing to load a request"
    )
  }

  func testEarlyExitFromLoadingInvokesAndClearsPendingCompletions() {
    var firstCompletionCallCount = 0
    AppEventsConfigurationManager.loadAppEventsConfiguration {
      firstCompletionCallCount += 1
    }
    var secondCompletionCallCount = 0
    AppEventsConfigurationManager.loadAppEventsConfiguration {
      secondCompletionCallCount += 1
    }

    settings.appID = nil
    var thirdCompletionCallCount = 0
    AppEventsConfigurationManager.loadAppEventsConfiguration {
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
    AppEventsConfigurationManager.loadAppEventsConfiguration {
      firstCompletionCallCount += 1
    }
    var secondCompletionCallCount = 0
    AppEventsConfigurationManager.loadAppEventsConfiguration {
      secondCompletionCallCount += 1
    }

    connection.capturedCompletion?(nil, RawAppEventsConfigurationResponseFixtures.valid, nil)

    XCTAssertEqual(firstCompletionCallCount, 1)
    XCTAssertEqual(secondCompletionCallCount, 1)
  }

  func testCompletingFetchClearsPendingCompletionHandlers() {
    var firstCompletionCallCount = 0
    AppEventsConfigurationManager.loadAppEventsConfiguration {
      firstCompletionCallCount += 1
    }
    var secondCompletionCallCount = 0
    AppEventsConfigurationManager.loadAppEventsConfiguration {
      secondCompletionCallCount += 1
    }

    connection.capturedCompletion?(nil, RawAppEventsConfigurationResponseFixtures.valid, nil)

    // Fetch without app id to early exit and invoke any pending completions
    settings.appID = nil
    AppEventsConfigurationManager.loadAppEventsConfiguration {}

    XCTAssertEqual(firstCompletionCallCount, 1)
    XCTAssertEqual(secondCompletionCallCount, 1)
  }

  func testLoadingWhileLoadingInProgress() {
    AppEventsConfigurationManager.loadAppEventsConfiguration {}
    AppEventsConfigurationManager.loadAppEventsConfiguration {}

    XCTAssertEqual(
      connection.startCallCount,
      1,
      "Should not start a request while a request is in progress"
    )

    connection.capturedCompletion?(nil, RawAppEventsConfigurationResponseFixtures.valid, nil)

    // Otherwise it won't try to fetch again so we cannot test that the
    // isLoading lock is reset.
    AppEventsConfigurationManager.shared.hasRequeryFinishedForAppStart = false

    AppEventsConfigurationManager.loadAppEventsConfiguration {}

    XCTAssertEqual(
      connection.startCallCount,
      2,
      "Should start a request if no request is in progress"
    )
  }

  func testLoadingWithFinishedRequeryAndValidTimestamp() {
    AppEventsConfigurationManager.loadAppEventsConfiguration {}
    connection.capturedCompletion?(nil, RawAppEventsConfigurationResponseFixtures.valid, nil)

    var completionCallCount = 0
    AppEventsConfigurationManager.loadAppEventsConfiguration {
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

    AppEventsConfigurationManager.loadAppEventsConfiguration {}

    XCTAssertEqual(
      connection.startCallCount,
      1,
      "Should fetch the configuration if the requery has finished but the timestamp is invalid"
    )
  }

  func testCompleteLoadingWithError() {
    AppEventsConfigurationManager.loadAppEventsConfiguration {
      XCTFail("Completing with an error should probably invoke the completions but it wont")
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
  }

  func testCompleteLoadingWithErrorDoesNotClearPendingCompletions() {
    var firstCompletionCallCount = 0
    AppEventsConfigurationManager.loadAppEventsConfiguration {
      firstCompletionCallCount += 1
    }
    var secondCompletionCallCount = 0
    AppEventsConfigurationManager.loadAppEventsConfiguration {
      secondCompletionCallCount += 1
    }

    // Completing with error should not clear any pending completion handlers
    connection.capturedCompletion?(nil, nil, SampleError())

    // Fetch without app id to early exit and invoke any pending completions
    settings.appID = nil
    AppEventsConfigurationManager.loadAppEventsConfiguration {}

    XCTAssertEqual(firstCompletionCallCount, 1)
    XCTAssertEqual(secondCompletionCallCount, 1)
  }

  func testUnarchivesStoredCaptureEvents() {
    // Validates unarchival from store
    AppEventsConfigurationManager.loadAppEventsConfiguration {}

    // Confirm default state
    XCTAssertEqual(AppEventsConfigurationManager.cachedAppEventsConfiguration().advertiserIDCollectionEnabled, true)
    XCTAssertEqual(AppEventsConfigurationManager.cachedAppEventsConfiguration().eventCollectionEnabled, false)
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
      graphRequestFactory: requestFactory,
      graphRequestConnectionFactory: connectionFactory
    )
    // Confirm configuration is unarchived from store instead of set again from defaults
    XCTAssertEqual(AppEventsConfigurationManager.cachedAppEventsConfiguration().advertiserIDCollectionEnabled, false)
    XCTAssertEqual(AppEventsConfigurationManager.cachedAppEventsConfiguration().eventCollectionEnabled, true)
 }
}
