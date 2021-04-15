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
import XCTest

class CodelessIndexerTests: XCTestCase { // swiftlint:disable:this type_body_length

  let requestFactory = TestGraphRequestFactory()
  let store = UserDefaultsSpy()
  let connection: TestGraphRequestConnection = TestGraphRequestConnection()
  lazy var connectionFactory: TestGraphRequestConnectionFactory = {
    return TestGraphRequestConnectionFactory.create(withStubbedConnection: connection)
  }()
  let settings = TestSettings()
  let advertiserIDProvider = TestAdvertiserIDProvider()
  let appID = "123"
  let enabledConfiguration = ServerConfigurationFixtures.config(with: ["codelessEventsEnabled": true])
  var codelessSettingStorageKey: String! // swiftlint:disable:this implicitly_unwrapped_optional
  var capturedIsEnabled = false
  var capturedError: Error?

  override func setUp() {
    super.setUp()

    CodelessIndexerTests.reset()

    settings.appID = name
    codelessSettingStorageKey = "com.facebook.sdk:codelessSetting\(name)"

    CodelessIndexer.configure(
      withRequestProvider: requestFactory,
      serverConfigurationProvider: TestServerConfigurationProvider.self,
      store: store,
      connectionProvider: connectionFactory,
      swizzler: TestSwizzler.self,
      settings: settings,
      advertiserIDProvider: advertiserIDProvider
    )
  }

  override class func tearDown() {
    super.tearDown()

    reset()
  }

  class func reset() {
    CodelessIndexer.reset()
    TestSwizzler.reset()
    TestServerConfigurationProvider.reset()
  }

  // MARK: - Dependencies

  func testDefaultDependencies() {
    CodelessIndexer.reset()

    XCTAssertNil(
      CodelessIndexer.requestProvider,
      "Should not have a request provider by default"
    )
    XCTAssertNil(
      CodelessIndexer.serverConfigurationProvider,
      "Should not have a server configuration provider by default"
    )
    XCTAssertNil(
      CodelessIndexer.store,
      "Should not have a persistent data store by default"
    )
    XCTAssertNil(
      CodelessIndexer.connectionProvider,
      "Should not have a connection provider by default"
    )
    XCTAssertNil(
      CodelessIndexer.swizzler,
      "Should not have a swizzler by default"
    )
    XCTAssertNil(
      CodelessIndexer.settings,
      "Should not have a settings instance by default"
    )
    XCTAssertNil(
      CodelessIndexer.advertiserIDProvider,
      "Should not have an advertiser ID provider by default"
    )
  }

  func testConfiguringWithDependencies() {
    XCTAssertEqual(
      CodelessIndexer.requestProvider as? TestGraphRequestFactory,
      requestFactory,
      "Should be able to configure with a request provider"
    )
    XCTAssertTrue(
      CodelessIndexer.serverConfigurationProvider is TestServerConfigurationProvider.Type,
      "Should be able to configure with a server configuration provider"
    )
    XCTAssertEqual(
      CodelessIndexer.store as? UserDefaultsSpy,
      store,
      "Should be able to configure with a persistent data store"
    )
    XCTAssertEqual(
      CodelessIndexer.connectionProvider as? TestGraphRequestConnectionFactory,
      connectionFactory,
      "Should be able to configure with a connection provider"
    )
    XCTAssertTrue(
      CodelessIndexer.swizzler is TestSwizzler.Type,
      "Should be able to configure with a swizzler"
    )
    XCTAssertTrue(
      CodelessIndexer.settings is TestSettings,
      "Should be able to configure with a settings"
    )
    XCTAssertTrue(
      CodelessIndexer.advertiserIDProvider is TestAdvertiserIDProvider,
      "Should be able to configure with an advertiser ID provider"
    )
  }

  // MARK: - Setup Request

  func testSetupRequestWithoutAdvertiserID() {
    XCTAssertNil(
      CodelessIndexer.requestToLoadCodelessSetup(appID: appID),
      "Should not create a request to load the codeless setup if there is no advertiser ID"
    )
  }

  func testSetupRequestWithAdvertiserID() {
    advertiserIDProvider.advertiserID = name

    CodelessIndexer.requestToLoadCodelessSetup(appID: appID)

    let expectedParameters = [
      "fields": "auto_event_setup_enabled",
      "advertiser_id": name
    ]
    XCTAssertEqual(
      requestFactory.capturedGraphPath,
      appID,
      "Should create a request using the app identifier as the path"
    )
    XCTAssertEqual(
      requestFactory.capturedParameters as? [String: String],
      expectedParameters,
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
      [.skipClientToken, .disableErrorRecovery],
      "Should create a request with the expected flags"
    )
  }

  // MARK: - Enabling

  func testEnablingSetsGesture() {
    CodelessIndexer.enable()

    XCTAssertTrue(
      TestSwizzler.evidence.contains(
        SwizzleEvidence(
          selector: #selector(UIApplication.motionBegan(_:with:)),
          class: UIApplication.self
        )
      )
    )
    TestSwizzler.reset()

    CodelessIndexer.enable()

    XCTAssertTrue(
      TestSwizzler.evidence.isEmpty,
      "Should only swizzle the shake gesture once"
    )
  }

  // MARK: - Loading Setup

  func testLoadingSettingWithoutAppID() {
    settings.appID = nil

    CodelessIndexer.loadCodelessSetting { _, _ in
      XCTFail("Should not load a codeless setting without an app identifier")
    }
    XCTAssertFalse(
      TestServerConfigurationProvider.loadServerConfigurationWasCalled,
      "Should not load the server configuration if the app identifier is missing"
    )
  }

  func testLoadingSettingWithCodelessEventsDisabledByConfiguration() {
    CodelessIndexer.loadCodelessSetting { _, _ in
      XCTFail("Should not load a codeless setting when codeless events are disabled")
    }
    TestServerConfigurationProvider.capturedCompletionBlock?(
      ServerConfigurationFixtures.defaultConfig(),
      nil
    )
    XCTAssertNil(
      store.capturedObjectRetrievalKey,
      "Should not attempt to read the cached codeless setting when codeless events are disabled"
    )
  }

  func testLoadingValidCachedSetting() throws {
    store.set(archivedSetting(), forKey: codelessSettingStorageKey)

    CodelessIndexer.loadCodelessSetting { isEnabled, potentialError in
      self.capturedIsEnabled = isEnabled
      self.capturedError = potentialError
    }

    TestServerConfigurationProvider.capturedCompletionBlock?(enabledConfiguration, nil)

    XCTAssertEqual(
      store.capturedObjectRetrievalKey,
      codelessSettingStorageKey,
      "Should read the cached codeless setting"
    )
    XCTAssertNil(
      capturedError,
      "Should not complete with an error when there is a valid cached setting"
    )
    XCTAssertTrue(
      capturedIsEnabled,
      "Should complete with the enabled value from cached setting"
    )
  }

  func testLoadingExpiredCachedSettingWithoutAdvertiserID() {
    store.set(archivedSetting(date: .distantPast), forKey: codelessSettingStorageKey)

    CodelessIndexer.loadCodelessSetting { _, _ in
      XCTFail("Should not invoke the completion")
    }

    TestServerConfigurationProvider.capturedCompletionBlock?(enabledConfiguration, nil)

    XCTAssertNil(
      connection.capturedRequest,
      "Should not add a request to fetch the codeless setting if there is no advertiser identifier"
    )
  }

  func testLoadingExpiredCachedSettingWithAdvertiserID() {
    advertiserIDProvider.advertiserID = name
    store.set(archivedSetting(date: .distantPast), forKey: codelessSettingStorageKey)

    CodelessIndexer.loadCodelessSetting { _, _ in
      XCTFail("Should not invoke the completion")
    }

    TestServerConfigurationProvider.capturedCompletionBlock?(enabledConfiguration, nil)

    XCTAssertNotNil(
      connection.capturedRequest,
      "Should add a request to fetch the codeless setting"
    )
    XCTAssertEqual(
      connection.startCallCount,
      1,
      "Should start the request to fetch the codeless setting"
    )
  }

  func testCompletingLoadingSettingWithOnlyError() {
    advertiserIDProvider.advertiserID = name
    store.set(archivedSetting(date: .distantPast), forKey: codelessSettingStorageKey)

    CodelessIndexer.loadCodelessSetting { _, _ in
      XCTFail("Should not invoke the completion if the network call completes with an error")
    }

    TestServerConfigurationProvider.capturedCompletionBlock?(enabledConfiguration, nil)

    connection.capturedCompletion?(nil, nil, SampleError())
  }

  func testCompletingLoadingSettingWithMissingResults() {
    advertiserIDProvider.advertiserID = name

    CodelessIndexer.loadCodelessSetting { isEnabled, potentialError in
      self.capturedIsEnabled = isEnabled
      self.capturedError = potentialError
    }

    TestServerConfigurationProvider.capturedCompletionBlock?(enabledConfiguration, nil)

    connection.capturedCompletion?(nil, nil, nil)

    XCTAssertNil(
      capturedError,
      "Should not complete with an error when there are missing results"
    )
    XCTAssertFalse(
      capturedIsEnabled,
      "Should complete with a default enabled value of false when there are no results"
    )
  }

  func testCompletingLoadingSettingWithInvalidResults() {
    advertiserIDProvider.advertiserID = name

    CodelessIndexer.loadCodelessSetting { isEnabled, potentialError in
      self.capturedIsEnabled = isEnabled
      self.capturedError = potentialError
    }

    TestServerConfigurationProvider.capturedCompletionBlock?(enabledConfiguration, nil)

    connection.capturedCompletion?(nil, ["foo": "bar"], nil)

    XCTAssertNil(
      capturedError,
      "Should not complete with an error when the results are invalid"
    )
    XCTAssertFalse(
      capturedIsEnabled,
      "Should complete with a default enabled value of false when the results are invalid"
    )
  }

  func testCompletingLoadingSettingWithValidResults() {
    advertiserIDProvider.advertiserID = name

    CodelessIndexer.loadCodelessSetting { isEnabled, potentialError in
      self.capturedIsEnabled = isEnabled
      self.capturedError = potentialError
    }

    TestServerConfigurationProvider.capturedCompletionBlock?(enabledConfiguration, nil)

    connection.capturedCompletion?(nil, ["auto_event_setup_enabled": true], nil)

    XCTAssertNil(capturedError)
    XCTAssertTrue(
      capturedIsEnabled,
      "Should complete with the enabled value from the network result"
    )
    XCTAssertEqual(
      store.capturedSetObjectKey,
      codelessSettingStorageKey,
      "Should persist the fetched setting"
    )
  }

  func testCompletingLoadingNewSettingWithExpiredCachedSetting() {
    advertiserIDProvider.advertiserID = name
    store.set(archivedSetting(date: .distantPast), forKey: codelessSettingStorageKey)

    CodelessIndexer.loadCodelessSetting { isEnabled, potentialError in
      self.capturedIsEnabled = isEnabled
      self.capturedError = potentialError
    }

    TestServerConfigurationProvider.capturedCompletionBlock?(enabledConfiguration, nil)

    connection.capturedCompletion?(nil, ["auto_event_setup_enabled": true], nil)

    XCTAssertNil(capturedError)
    XCTAssertTrue(
      capturedIsEnabled,
      "Should complete with the enabled value from the network result"
    )
    XCTAssertEqual(
      store.capturedSetObjectKey,
      codelessSettingStorageKey,
      "Should persist the fetched setting"
    )
  }

  // MARK: - Helpers

  func archivedSetting(
    isEnabled: Bool = true,
    date: Date = Date()
  ) -> Data {
    return NSKeyedArchiver.archivedData(
      withRootObject: [
        "codeless_setup_enabled": isEnabled,
        "codeless_setting_timestamp": date
      ]
    )
  }
} // swiftlint:disable:this file_length
