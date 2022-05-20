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

final class CodelessIndexerTests: XCTestCase {

  let graphRequestFactory = TestGraphRequestFactory()
  let dataStore = UserDefaultsSpy()
  let connection = TestGraphRequestConnection()
  lazy var graphRequestConnectionFactory = TestGraphRequestConnectionFactory.create(withStubbedConnection: connection)
  let settings = TestSettings()
  let advertiserIDProvider = TestAdvertiserIDProvider()
  let appID = "123"
  let enabledConfiguration = ServerConfigurationFixtures.configuration(withDictionary: ["codelessEventsEnabled": true])
  let serverConfigurationProvider = TestServerConfigurationProvider()
  lazy var codelessSettingStorageKey = "com.facebook.sdk:codelessSetting\(name)"
  var capturedIsEnabled = false
  var capturedError: Error?
  let frame = CGRect(x: 20, y: 20, width: 36, height: 36)
  lazy var view = UIView(frame: frame)
  let autoEventSetupEnabled = "auto_event_setup_enabled"

  enum Keys {
    static let codelessEnabled = "is_app_indexing_enabled"
    static let fields = "fields"
    static let advertiserID = "advertiser_id"
    static let deviceSessionID = "device_session_id"
    static let extInfo = "extinfo"
  }

  override func setUp() {
    super.setUp()

    Self.reset()

    settings.appID = name

    CodelessIndexer.configure(
      graphRequestFactory: graphRequestFactory,
      serverConfigurationProvider: serverConfigurationProvider,
      dataStore: dataStore,
      graphRequestConnectionFactory: graphRequestConnectionFactory,
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
  }

  // MARK: - Dependencies

  func testDefaultDependencies() {
    CodelessIndexer.reset()

    XCTAssertNil(
      CodelessIndexer.graphRequestFactory,
      "Should not have a request provider by default"
    )
    XCTAssertNil(
      CodelessIndexer.serverConfigurationProvider,
      "Should not have a server configuration provider by default"
    )
    XCTAssertNil(
      CodelessIndexer.dataStore,
      "Should not have a persistent data store by default"
    )
    XCTAssertNil(
      CodelessIndexer.graphRequestConnectionFactory,
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
      CodelessIndexer.graphRequestFactory as? TestGraphRequestFactory,
      graphRequestFactory,
      "Should be able to configure with a request provider"
    )
    XCTAssertTrue(
      CodelessIndexer.serverConfigurationProvider is TestServerConfigurationProvider,
      "Should be able to configure with a server configuration provider"
    )
    XCTAssertEqual(
      CodelessIndexer.dataStore as? UserDefaultsSpy,
      dataStore,
      "Should be able to configure with a persistent data store"
    )
    XCTAssertEqual(
      CodelessIndexer.graphRequestConnectionFactory as? TestGraphRequestConnectionFactory,
      graphRequestConnectionFactory,
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
      Keys.fields: autoEventSetupEnabled,
      Keys.advertiserID: name,
    ]
    XCTAssertEqual(
      graphRequestFactory.capturedGraphPath,
      appID,
      "Should create a request using the app identifier as the path"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedParameters as? [String: String],
      expectedParameters,
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
      serverConfigurationProvider.loadServerConfigurationWasCalled,
      "Should not load the server configuration if the app identifier is missing"
    )
  }

  func testLoadingSettingWithCodelessEventsDisabledByConfiguration() {
    CodelessIndexer.loadCodelessSetting { _, _ in
      XCTFail("Should not load a codeless setting when codeless events are disabled")
    }
    serverConfigurationProvider.capturedCompletionBlock?(
      ServerConfigurationFixtures.defaultConfiguration,
      nil
    )
    XCTAssertNil(
      dataStore.capturedObjectRetrievalKey,
      "Should not attempt to read the cached codeless setting when codeless events are disabled"
    )
  }

  func testLoadingValidCachedSetting() throws {
    dataStore.set(archivedSetting(), forKey: codelessSettingStorageKey)

    CodelessIndexer.loadCodelessSetting { isEnabled, potentialError in
      self.capturedIsEnabled = isEnabled
      self.capturedError = potentialError
    }

    serverConfigurationProvider.capturedCompletionBlock?(enabledConfiguration, nil)

    XCTAssertEqual(
      dataStore.capturedObjectRetrievalKey,
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
    dataStore.set(archivedSetting(date: .distantPast), forKey: codelessSettingStorageKey)

    CodelessIndexer.loadCodelessSetting { _, _ in
      XCTFail("Should not invoke the completion")
    }

    serverConfigurationProvider.capturedCompletionBlock?(enabledConfiguration, nil)

    XCTAssertNil(
      connection.capturedRequest,
      "Should not add a request to fetch the codeless setting if there is no advertiser identifier"
    )
  }

  func testLoadingExpiredCachedSettingWithAdvertiserID() {
    advertiserIDProvider.advertiserID = name
    dataStore.set(archivedSetting(date: .distantPast), forKey: codelessSettingStorageKey)

    CodelessIndexer.loadCodelessSetting { _, _ in
      XCTFail("Should not invoke the completion")
    }

    serverConfigurationProvider.capturedCompletionBlock?(enabledConfiguration, nil)

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
    dataStore.set(archivedSetting(date: .distantPast), forKey: codelessSettingStorageKey)

    CodelessIndexer.loadCodelessSetting { _, _ in
      XCTFail("Should not invoke the completion if the network call completes with an error")
    }

    serverConfigurationProvider.capturedCompletionBlock?(enabledConfiguration, nil)

    connection.capturedCompletion?(nil, nil, SampleError())
  }

  func testCompletingLoadingSettingWithMissingResults() {
    advertiserIDProvider.advertiserID = name

    CodelessIndexer.loadCodelessSetting { isEnabled, potentialError in
      self.capturedIsEnabled = isEnabled
      self.capturedError = potentialError
    }

    serverConfigurationProvider.capturedCompletionBlock?(enabledConfiguration, nil)

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

    serverConfigurationProvider.capturedCompletionBlock?(enabledConfiguration, nil)

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

    serverConfigurationProvider.capturedCompletionBlock?(enabledConfiguration, nil)

    connection.capturedCompletion?(nil, [autoEventSetupEnabled: true], nil)

    XCTAssertNil(capturedError)
    XCTAssertTrue(
      capturedIsEnabled,
      "Should complete with the enabled value from the network result"
    )
    XCTAssertEqual(
      dataStore.capturedSetObjectKey,
      codelessSettingStorageKey,
      "Should persist the fetched setting"
    )
  }

  func testCompletingLoadingNewSettingWithExpiredCachedSetting() {
    advertiserIDProvider.advertiserID = name
    dataStore.set(archivedSetting(date: .distantPast), forKey: codelessSettingStorageKey)

    CodelessIndexer.loadCodelessSetting { isEnabled, potentialError in
      self.capturedIsEnabled = isEnabled
      self.capturedError = potentialError
    }

    serverConfigurationProvider.capturedCompletionBlock?(enabledConfiguration, nil)

    connection.capturedCompletion?(nil, [autoEventSetupEnabled: true], nil)

    XCTAssertNil(capturedError)
    XCTAssertTrue(
      capturedIsEnabled,
      "Should complete with the enabled value from the network result"
    )
    XCTAssertEqual(
      dataStore.capturedSetObjectKey,
      codelessSettingStorageKey,
      "Should persist the fetched setting"
    )
  }

  // MARK: - Uploading Indexing

  enum SampleViewHierarchyTrees {
    static let empty = ""
    static let valid = "UIButton"
  }

  func testUploadingWithoutAppID() {
    settings.appID = nil
    CodelessIndexer.uploadIndexing(SampleViewHierarchyTrees.empty)

    XCTAssertNotNil(
      graphRequestFactory.capturedGraphPath,
      "Should not create an upload request without an app identifier but it will"
    )
  }

  func testUploadingWithoutViewHierarchy() {
    CodelessIndexer.uploadIndexing(nil)

    XCTAssertNil(
      graphRequestFactory.capturedGraphPath,
      "Should not create an upload request without a view hierarchy"
    )
  }

  func testUploadingWithEmptyViewHierarchy() {
    CodelessIndexer.uploadIndexing(SampleViewHierarchyTrees.empty)

    XCTAssertNotNil(
      graphRequestFactory.capturedGraphPath,
      "Should not create an upload request with an empty view hierarchy but it will"
    )
  }

  func testUploadingWhileUploadInProgress() {
    CodelessIndexer.uploadIndexing(SampleViewHierarchyTrees.valid)
    // Reset the test evidence to be able to check that the second call
    // does not create a graph request
    graphRequestFactory.capturedGraphPath = nil
    CodelessIndexer.uploadIndexing(SampleViewHierarchyTrees.valid)

    XCTAssertNil(
      graphRequestFactory.capturedGraphPath,
      "Should not create an upload request if an upload is in progress"
    )
  }

  func testUploadingIdenticalViewHierarchy() {
    CodelessIndexer.uploadIndexing(SampleViewHierarchyTrees.valid)
    // Reset the flag so that it treats the first call as completed
    CodelessIndexer.resetIsCodelessIndexing()
    // Reset the test evidence to be able to check that the second call
    // does not create a graph request
    graphRequestFactory.capturedGraphPath = nil
    CodelessIndexer.uploadIndexing(SampleViewHierarchyTrees.valid)

    XCTAssertNil(
      graphRequestFactory.capturedGraphPath,
      "Should not create an upload request for a hierarchy that is identical to one that was previously uploaded"
    )
  }

  func testUploadRequest() {
    CodelessIndexer.uploadIndexing(SampleViewHierarchyTrees.valid)

    XCTAssertEqual(
      graphRequestFactory.capturedGraphPath,
      "\(settings.appID!)/app_indexing", // swiftlint:disable:this force_unwrapping
      "Should create a request with the expected graph path"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedHttpMethod,
      .post,
      "Should create a request with the expected http method"
    )

    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""

    XCTAssertEqual(
      graphRequestFactory.capturedParameters as? [String: String],
      [
        "app_version": appVersion,
        Keys.deviceSessionID: CodelessIndexer.currentSessionDeviceID!, // swiftlint:disable:this force_unwrapping
        "platform": "iOS",
        "tree": "UIButton",
      ],
      "Should create a request with the expected parameters"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedFlags,
      [],
      "Should create a request with the expected flags"
    )
  }

  func testCompletingUploadWithoutInformation() {
    let sessionID = CodelessIndexer.currentSessionDeviceID
    CodelessIndexer.uploadIndexing(SampleViewHierarchyTrees.valid)

    guard let completion = graphRequestFactory.capturedRequests.first?.capturedCompletionHandler else {
      return XCTFail("Should start a request with a completion handler")
    }
    completion(nil, nil, nil)

    XCTAssertEqual(
      sessionID,
      CodelessIndexer.currentSessionDeviceID,
      "Completing with no results or error should be treated as a noop"
    )
  }

  func testCompletingUploadWithErrorOnly() {
    let sessionID = CodelessIndexer.currentSessionDeviceID
    CodelessIndexer.uploadIndexing(SampleViewHierarchyTrees.valid)

    guard let completion = graphRequestFactory.capturedRequests.first?.capturedCompletionHandler else {
      return XCTFail("Should start a request with a completion handler")
    }
    completion(nil, nil, SampleError())

    XCTAssertEqual(
      sessionID,
      CodelessIndexer.currentSessionDeviceID,
      "Completing with only an error should be treated as a noop"
    )
  }

  func testCompletingUploadWithResultsIndicatingThatCodelessIsEnabled() {
    let sessionID = CodelessIndexer.currentSessionDeviceID
    CodelessIndexer.uploadIndexing(SampleViewHierarchyTrees.valid)

    guard let completion = graphRequestFactory.capturedRequests.first?.capturedCompletionHandler else {
      return XCTFail("Should start a request with a completion handler")
    }
    completion(nil, [Keys.codelessEnabled: true], nil)

    XCTAssertEqual(
      sessionID,
      CodelessIndexer.currentSessionDeviceID,
      "Completing with results indicating that codeless is enabled should be treated as a noop"
    )
  }

  func testCompletingUploadWithResultsIndicatingThatCodelessIsDisabled() {
    let sessionID = CodelessIndexer.currentSessionDeviceID
    CodelessIndexer.uploadIndexing(SampleViewHierarchyTrees.valid)

    guard let completion = graphRequestFactory.capturedRequests.first?.capturedCompletionHandler else {
      return XCTFail("Should start a request with a completion handler")
    }
    completion(nil, [Keys.codelessEnabled: false], nil)

    XCTAssertNotEqual(
      sessionID,
      CodelessIndexer.currentSessionDeviceID,
      """
      Completing with results indicating that codeless is disabled should
      reset the session identifier
      """
    )
  }

  // MARK: - Checking Indexing Session

  func testCheckingIndexingSessionWhileIndexing() {
    CodelessIndexer.checkCodelessIndexingSession()
    graphRequestFactory.capturedRequests.first?.capturedCompletionHandler = nil
    CodelessIndexer.checkCodelessIndexingSession()

    XCTAssertNil(
      graphRequestFactory.capturedRequests.first?.capturedCompletionHandler,
      "Should not create a second request to cehck the indexing status if the first is incomplete"
    )
  }

  func testCheckingIndexingSessionRequest() {
    CodelessIndexer.checkCodelessIndexingSession()

    guard let sessionID = CodelessIndexer.currentSessionDeviceID else {
      return XCTFail("Should provide a session device identifier")
    }

    let expectedParameters = [
      Keys.deviceSessionID: sessionID,
      Keys.extInfo: CodelessIndexer.extInfo,
    ]

    XCTAssertEqual(
      graphRequestFactory.capturedGraphPath,
      "\(name)/app_indexing_session",
      "Should request the session with the expected graph path"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedParameters as? [String: String],
      expectedParameters,
      "Should request the session with the expected parameters"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedHttpMethod,
      .post,
      "Should request the session with the expected http method"
    )
  }

  func testCompleteCheckingIndexingSessionWithNoInput() {
    CodelessIndexer.checkCodelessIndexingSession()

    graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(nil, nil, nil)

    XCTAssertFalse(
      CodelessIndexer.isCheckingSession,
      "Should reset the ability to check a session after the request completes"
    )
    XCTAssertNil(
      CodelessIndexer.appIndexingTimer,
      "Should not create an indexing timer without a result"
    )
  }

  func testCompleteCheckingIndexingSessionWithErrorOnly() {
    CodelessIndexer.checkCodelessIndexingSession()

    graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(nil, nil, SampleError())

    XCTAssertFalse(CodelessIndexer.isCheckingSession)
    XCTAssertNil(
      CodelessIndexer.appIndexingTimer,
      "Should not create an indexing timer if there is an error"
    )
  }

  func testCompleteCheckingIndexingSessionWithInvalidResults() {
    CodelessIndexer.checkCodelessIndexingSession()

    (1 ... 20).forEach { _ in
      graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(nil, Fuzzer.random, nil)

      XCTAssertNil(
        CodelessIndexer.appIndexingTimer,
        "Should not create an indexing timer if the result is invalid"
      )
    }
  }

  func testCompletingCheckingIndexingWithCodelessEnabledResult() {
    CodelessIndexer.checkCodelessIndexingSession()

    graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(nil, [Keys.codelessEnabled: true], nil)

    XCTAssertFalse(CodelessIndexer.isCheckingSession)
    XCTAssertNotNil(
      CodelessIndexer.appIndexingTimer,
      "Should create an indexing timer if the result indicates that codeless is enabled"
    )
    // Invalidate for cleanup
    CodelessIndexer.appIndexingTimer?.invalidate()
  }

  func testCompletingCheckingIndexingWithCodelessDisabledResult() {
    let sessionIdentifier = CodelessIndexer.currentSessionDeviceID
    CodelessIndexer.checkCodelessIndexingSession()

    graphRequestFactory.capturedRequests.first?.capturedCompletionHandler?(nil, [Keys.codelessEnabled: false], nil)

    XCTAssertFalse(CodelessIndexer.isCheckingSession)
    XCTAssertNil(
      CodelessIndexer.appIndexingTimer,
      "Should not create an indexing timer if the result indicates that codeless is disabled"
    )
    XCTAssertNotEqual(
      sessionIdentifier,
      CodelessIndexer.currentSessionDeviceID,
      "Should reset the current session device identifier if the result indicates that codeless is disabled"
    )
  }

  // MARK: - Miscellaneous

  func testExtraInfo() throws {
    var systemInfo = utsname()
    uname(&systemInfo)
    let data = Data(bytes: &systemInfo.machine, count: Int(_SYS_NAMELEN))
    let machine = try XCTUnwrap(
      String(bytes: data, encoding: .ascii)?.trimmingCharacters(in: .controlCharacters),
      "Unable to find host architecture"
    )

    XCTAssertEqual(
      CodelessIndexer.extInfo,
      """
      ["\(machine)","","1","1","en_US"]
      """,
      "Should be able to provide extra info as a string representation of an array of strings"
    )
  }

  func testCurrentSessionDeviceID() {
    let identifier = CodelessIndexer.currentSessionDeviceID

    XCTAssertEqual(
      CodelessIndexer.currentSessionDeviceID,
      identifier,
      "Should only create a single session device ID"
    )

    CodelessIndexer.reset()

    XCTAssertNotEqual(
      CodelessIndexer.currentSessionDeviceID,
      identifier,
      "Should create unique session device IDs per sdk launch"
    )
  }

  func testDimensionOfNonView() {
    let dimensions = CodelessIndexer.dimension(of: "" as NSString)

    XCTAssertEqual(
      dimensions,
      [
        CODELESS_VIEW_TREE_TOP_KEY: 0,
        CODELESS_VIEW_TREE_LEFT_KEY: 0,
        CODELESS_VIEW_TREE_WIDTH_KEY: 0,
        CODELESS_VIEW_TREE_HEIGHT_KEY: 0,
        CODELESS_VIEW_TREE_OFFSET_X_KEY: 0,
        CODELESS_VIEW_TREE_OFFSET_Y_KEY: 0,
        CODELESS_VIEW_TREE_VISIBILITY_KEY: 0,
      ],
      "Dimension of a non-view should be considered to be zero"
    )
  }

  func testDimensionOfView() {
    let dimensions = CodelessIndexer.dimension(of: view)

    XCTAssertEqual(
      dimensions,
      [
        CODELESS_VIEW_TREE_TOP_KEY: 20,
        CODELESS_VIEW_TREE_LEFT_KEY: 20,
        CODELESS_VIEW_TREE_WIDTH_KEY: 36,
        CODELESS_VIEW_TREE_HEIGHT_KEY: 36,
        CODELESS_VIEW_TREE_OFFSET_X_KEY: 0,
        CODELESS_VIEW_TREE_OFFSET_Y_KEY: 0,
        CODELESS_VIEW_TREE_VISIBILITY_KEY: 0,
      ],
      "Should calculate the correct view dimensions"
    )
  }

  func testDimensionOfViewController() {
    let controller = UIViewController()
    controller.view = view
    let dimensions = CodelessIndexer.dimension(of: controller)

    XCTAssertEqual(
      dimensions,
      [
        CODELESS_VIEW_TREE_TOP_KEY: 20,
        CODELESS_VIEW_TREE_LEFT_KEY: 20,
        CODELESS_VIEW_TREE_WIDTH_KEY: 36,
        CODELESS_VIEW_TREE_HEIGHT_KEY: 36,
        CODELESS_VIEW_TREE_OFFSET_X_KEY: 0,
        CODELESS_VIEW_TREE_OFFSET_Y_KEY: 0,
        CODELESS_VIEW_TREE_VISIBILITY_KEY: 0,
      ],
      "Should calculate the correct view dimensions"
    )
  }

  func testDimensionOfScrollView() {
    let view = UIScrollView(frame: frame)
    view.setContentOffset(CGPoint(x: 100, y: 100), animated: false)
    let dimensions = CodelessIndexer.dimension(of: view)

    XCTAssertEqual(
      dimensions,
      [
        CODELESS_VIEW_TREE_TOP_KEY: 20,
        CODELESS_VIEW_TREE_LEFT_KEY: 20,
        CODELESS_VIEW_TREE_WIDTH_KEY: 36,
        CODELESS_VIEW_TREE_HEIGHT_KEY: 36,
        CODELESS_VIEW_TREE_OFFSET_X_KEY: 100,
        CODELESS_VIEW_TREE_OFFSET_Y_KEY: 100,
        CODELESS_VIEW_TREE_VISIBILITY_KEY: 0,
      ],
      "Should calculate the correct view dimensions"
    )
  }

  func testDimensionOfHiddenView() {
    view.isHidden = true
    let dimensions = CodelessIndexer.dimension(of: view)

    XCTAssertEqual(
      dimensions,
      [
        CODELESS_VIEW_TREE_TOP_KEY: 20,
        CODELESS_VIEW_TREE_LEFT_KEY: 20,
        CODELESS_VIEW_TREE_WIDTH_KEY: 36,
        CODELESS_VIEW_TREE_HEIGHT_KEY: 36,
        CODELESS_VIEW_TREE_OFFSET_X_KEY: 0,
        CODELESS_VIEW_TREE_OFFSET_Y_KEY: 0,
        CODELESS_VIEW_TREE_VISIBILITY_KEY: 4,
      ],
      "Should calculate the correct view dimensions and indicate hidden status"
    )
  }

  // MARK: - Helpers

  func archivedSetting(
    isEnabled: Bool = true,
    date: Date = Date()
  ) -> Data {
    NSKeyedArchiver.archivedData(
      withRootObject: [
        "codeless_setup_enabled": isEnabled,
        "codeless_setting_timestamp": date,
      ]
    )
  }
}
