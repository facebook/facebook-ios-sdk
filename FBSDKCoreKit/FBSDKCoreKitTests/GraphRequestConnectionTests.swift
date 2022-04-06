/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import UIKit
import XCTest

final class GraphRequestConnectionTests: XCTestCase, GraphRequestConnectionDelegate {

  let appID = "appid"
  var didInvokeDelegateRequestConnectionDidSendBodyData = false

  // swiftlint:disable implicitly_unwrapped_optional force_unwrapping line_length
  let sampleUrl = URL(string: "https://example.com")!
  let missingTokenData = "{\"error\": {\"message\": \"Token is broken\",\"code\": 190,\"error_subcode\": 463}}".data(using: .utf8)!
  let clientToken = "client_token"
  var session: TestURLSessionProxy!
  var secondSession: TestURLSessionProxy!
  var sessionFactory: TestURLSessionProxyFactory!
  var errorConfiguration: TestErrorConfiguration!
  var errorConfigurationProvider: TestErrorConfigurationProvider!
  var errorRecoveryConfiguration: ErrorRecoveryConfiguration!
  var settings: TestSettings!
  var graphRequestConnectionFactory: TestGraphRequestConnectionFactory!
  var eventLogger: TestEventLogger!
  var processInfo: TestProcessInfo!
  var macCatalystDeterminator: TestMacCatalystDeterminator!
  var logger: TestLogger!
  var connection: GraphRequestConnection!
  var errorFactory: TestErrorFactory!
  var metadata: GraphRequestMetadata!
  var piggybackManager: TestGraphRequestPiggybackManager!
  // swiftlint:enable implicitly_unwrapped_optional force_unwrapping line_length

  func createSampleMetadata() -> GraphRequestMetadata {
    GraphRequestMetadata(
      request: makeSampleRequest(),
      completionHandler: nil,
      batchParameters: nil
    )
  }

  var requestConnectionStartingCallback: ((GraphRequestConnecting) -> Void)?
  var requestConnectionCallback: ((GraphRequestConnecting, Error?) -> Void)?

  override func setUp() {
    super.setUp()

    metadata = createSampleMetadata()
    TestAccessTokenWallet.reset()
    TestAuthenticationTokenWallet.reset()
    GraphRequestConnection.setCanMakeRequests()

    session = TestURLSessionProxy()
    secondSession = TestURLSessionProxy()
    sessionFactory = TestURLSessionProxyFactory.create(withSessions: [session, secondSession])
    errorRecoveryConfiguration = makeNonTransientErrorRecoveryConfiguration()
    errorConfiguration = TestErrorConfiguration()
    errorConfiguration.stubbedRecoveryConfiguration = errorRecoveryConfiguration
    errorConfigurationProvider = TestErrorConfigurationProvider(configuration: errorConfiguration)
    settings = TestSettings()
    settings.appID = appID
    settings.clientToken = clientToken
    graphRequestConnectionFactory = TestGraphRequestConnectionFactory()
    eventLogger = TestEventLogger()
    processInfo = TestProcessInfo()
    macCatalystDeterminator = TestMacCatalystDeterminator()
    logger = TestLogger(loggingBehavior: .developerErrors)
    errorFactory = TestErrorFactory()
    piggybackManager = TestGraphRequestPiggybackManager()
    GraphRequestConnection.configure(
      withURLSessionProxyFactory: sessionFactory,
      errorConfigurationProvider: errorConfigurationProvider,
      piggybackManager: piggybackManager,
      settings: settings,
      graphRequestConnectionFactory: graphRequestConnectionFactory,
      eventLogger: eventLogger,
      operatingSystemVersionComparer: processInfo,
      macCatalystDeterminator: macCatalystDeterminator,
      accessTokenProvider: TestAccessTokenWallet.self,
      accessTokenSetter: TestAccessTokenWallet.self,
      errorFactory: errorFactory,
      authenticationTokenProvider: TestAuthenticationTokenWallet.self
    )
    connection = GraphRequestConnection()
    graphRequestConnectionFactory.stubbedConnection = connection
  }

  override func tearDown() {
    session = nil
    secondSession = nil
    sessionFactory = nil
    errorConfiguration = nil
    errorConfigurationProvider = nil
    errorRecoveryConfiguration = nil
    settings = nil
    graphRequestConnectionFactory = nil
    eventLogger = nil
    processInfo = nil
    macCatalystDeterminator = nil
    logger = nil
    connection = nil
    errorFactory = nil
    metadata = nil
    piggybackManager = nil

    GraphRequestConnection.resetClassDependencies()
    GraphRequestConnection.resetDefaultConnectionTimeout()
    GraphRequestConnection.resetCanMakeRequests()
    TestLogger.reset()
    TestAccessTokenWallet.reset()
    TestAuthenticationTokenWallet.reset()

    super.tearDown()
  }

  // MARK: - GraphRequestConnectionDelegate

  func requestConnection(_ connection: GraphRequestConnecting, didFailWithError error: Error) {
    if let completion = requestConnectionCallback {
      completion(connection, error)
      requestConnectionCallback = nil
    }
  }

  func requestConnectionDidFinishLoading(_ connection: GraphRequestConnecting) {
    if let completion = requestConnectionCallback {
      completion(connection, nil)
      requestConnectionCallback = nil
    }
  }

  func requestConnectionWillBeginLoading(_ connection: GraphRequestConnecting) {
    if let completion = requestConnectionStartingCallback {
      completion(connection)
      requestConnectionStartingCallback = nil
    }
  }

  func requestConnection(
    _ connection: GraphRequestConnecting,
    didSendBodyData bytesWritten: Int,
    totalBytesWritten: Int,
    totalBytesExpectedToWrite: Int
  ) {
    didInvokeDelegateRequestConnectionDidSendBodyData = true
  }

  // MARK: - Dependencies

  func testDefaultDependencies() {
    GraphRequestConnection.resetClassDependencies()

    XCTAssertNil(
      GraphRequestConnection.sessionProxyFactory,
      "A graph request connection should not have a session provider by default"
    )
    XCTAssertNil(
      GraphRequestConnection.errorConfigurationProvider,
      "A graph request connection should not have a error configuration provider by default"
    )
    XCTAssertNil(
      GraphRequestConnection.piggybackManager,
      "A graph request connection should not have a piggyback manager by default"
    )
    XCTAssertNil(
      GraphRequestConnection.settings,
      "A graph request connection should not have a settings type by default"
    )
    XCTAssertNil(
      GraphRequestConnection.graphRequestConnectionFactory,
      "A graph request connection should not have a connection factory by default"
    )
    XCTAssertNil(
      GraphRequestConnection.eventLogger,
      "A graph request connection should not have an events logger by default"
    )
    XCTAssertNil(
      GraphRequestConnection.operatingSystemVersionComparer,
      "A graph request connection should not have an operating system version comparer by default"
    )
    XCTAssertNil(
      GraphRequestConnection.macCatalystDeterminator,
      "A graph request connection should not have a Mac Catalyst determinator by default"
    )
    XCTAssertNil(
      GraphRequestConnection.accessTokenProvider,
      "A graph request connection should not an access token provider by default"
    )
    XCTAssertNil(
      GraphRequestConnection.accessTokenSetter,
      "A graph request connection should not have an access token setter by default"
    )
    XCTAssertNil(
      GraphRequestConnection.errorFactory,
      "A graph request connection should not have an error factory by default"
    )
    XCTAssertNil(
      GraphRequestConnection.authenticationTokenProvider,
      "A graph request connection should not have an authentication token provider by default"
    )
  }

  func testCreatingWithCustomDependencies() {
    XCTAssertTrue(
      GraphRequestConnection.sessionProxyFactory === sessionFactory,
      "A graph request connection should persist the session provider it was created with"
    )
    XCTAssertTrue(
      connection.session === session,
      "A graph request connection should derive sessions from the session provider"
    )
    XCTAssertTrue(
      GraphRequestConnection.errorConfigurationProvider === errorConfigurationProvider,
      "A graph request connection should persist the error configuration provider it was created with"
    )
    XCTAssertTrue(
      GraphRequestConnection.piggybackManager === piggybackManager,
      "A graph request connection should persist the piggyback manager it was created with"
    )
    XCTAssertTrue(
      GraphRequestConnection.settings === settings,
      "A graph request connection should persist the settings it was created with"
    )
    XCTAssertTrue(
      GraphRequestConnection.graphRequestConnectionFactory === graphRequestConnectionFactory,
      "A graph request connection should persist the connection factory it was created with"
    )
    XCTAssertTrue(
      GraphRequestConnection.eventLogger === eventLogger,
      "A graph request connection should persist the events logger it was created with"
    )
    XCTAssertTrue(
      GraphRequestConnection.operatingSystemVersionComparer === processInfo,
      "A graph request connection should persist the operating system comparer it was created with"
    )
    XCTAssertTrue(
      GraphRequestConnection.macCatalystDeterminator === macCatalystDeterminator,
      "A graph request connection should persist the Mac Catalyst determinator it was created with"
    )
    XCTAssertTrue(
      GraphRequestConnection.accessTokenProvider === TestAccessTokenWallet.self,
      "A graph request connection should persist the access token provider it was created with"
    )
    XCTAssertTrue(
      GraphRequestConnection.accessTokenSetter === TestAccessTokenWallet.self,
      "A graph request connection should persist the access token setter it was created with"
    )
    XCTAssertTrue(
      GraphRequestConnection.errorFactory === errorFactory,
      "A graph request connection should persist the error factory it was created with"
    )
    XCTAssertTrue(
      GraphRequestConnection.authenticationTokenProvider === TestAuthenticationTokenWallet.self,
      "A graph request connection should persist the authentication token provider it was created with"
    )
  }

  // MARK: - Properties

  func testDefaultConnectionTimeout() {
    XCTAssertEqual(
      GraphRequestConnection.defaultConnectionTimeout,
      60,
      "Should have a default connection timeout of 60 seconds"
    )
  }

  func testOverridingDefaultConnectionTimeoutWithInvalidTimeout() {
    GraphRequestConnection.defaultConnectionTimeout = -1
    XCTAssertEqual(
      GraphRequestConnection.defaultConnectionTimeout,
      60,
      "Should not be able to override the default connection timeout with an invalid timeout"
    )
  }

  func testOverridingDefaultConnectionTimeoutWithValidTimeout() {
    GraphRequestConnection.defaultConnectionTimeout = 100
    XCTAssertEqual(
      GraphRequestConnection.defaultConnectionTimeout,
      100,
      "Should be able to override the default connection timeout"
    )
  }

  func testDefaultOverriddenVersionPart() {
    XCTAssertNil(
      connection.overriddenVersionPart,
      "There should not be an overridden version part by default"
    )
  }

  func testOverridingVersionPartWithInvalidVersions() {
    ["", "abc", "-5", "1.1.1.1.1", "v1.1.1.1"]
      .forEach { string in
        connection.overrideGraphAPIVersion(string)
        XCTAssertEqual(
          connection.overriddenVersionPart,
          string,
          "Should not be able to override the graph api version with \(string) but you can"
        )
      }
  }

  func testOverridingVersionPartWithValidVersions() {
    ["1", "1.1", "1.1.1", "v1", "v1.1", "v1.1.1"]
      .forEach { string in
        connection.overrideGraphAPIVersion(string)
        XCTAssertEqual(
          connection.overriddenVersionPart,
          string,
          "Should be able to override the graph api version with a valid version string"
        )
      }
  }

  func testOverridingVersionCopies() {
    var version = "v1.0"
    connection.overrideGraphAPIVersion(version)
    version = "foo"

    XCTAssertNotEqual(
      version,
      connection.overriddenVersionPart,
      "Should copy the version so that changes to the original string do not affect the stored value"
    )
  }

  func testDefaultCanMakeRequests() {
    GraphRequestConnection.resetCanMakeRequests()
    XCTAssertFalse(
      GraphRequestConnection.canMakeRequests(),
      "Should not be able to make requests by default"
    )
  }

  func testDelegateQueue() {
    XCTAssertNil(connection.delegateQueue, "Should not have a delegate queue by default")
  }

  func testSettingDelegateQueue() {
    let queue = OperationQueue()
    connection.delegateQueue = queue
    XCTAssertEqual(
      connection.delegateQueue,
      queue,
      "Should be able to set the delegate queue"
    )
    XCTAssertEqual(
      session.delegateQueue,
      queue,
      "Should set the session's delegate queue when setting the connnection's delegate queue"
    )
  }

  // MARK: - Adding Requests

  func testAddingRequestWithoutBatchEntryName() throws {
    connection.add(makeRequestForMeWithEmptyFields()) { _, _, _ in }
    let metadata = try XCTUnwrap(connection.requests.firstObject as? GraphRequestMetadata)

    XCTAssertTrue(
      metadata.batchParameters.isEmpty,
      "Adding a request without a batch entry name should not store batch parameters"
    )
  }

  func testAddingRequestWithEmptyBatchEntryName() throws {
    connection.add(
      makeRequestForMeWithEmptyFields(),
      name: ""
    ) { _, _, _ in }
    let metadata = try XCTUnwrap(connection.requests.firstObject as? GraphRequestMetadata)

    XCTAssertTrue(
      metadata.batchParameters.isEmpty,
      "Should not store batch parameters for a request with an empty batch entry name"
    )
  }

  func testAddingRequestWithValidBatchEntryName() throws {
    connection.add(
      makeRequestForMeWithEmptyFields(),
      name: "foo"
    ) { _, _, _ in }
    let expectedParameters = ["name": "foo"]
    let metadata = try XCTUnwrap(connection.requests.firstObject as? GraphRequestMetadata)

    XCTAssertEqual(
      metadata.batchParameters as? [String: String],
      expectedParameters,
      "Should create and store batch parameters for a request with a non-empty batch entry name"
    )
  }

  func testAddingRequestWithBatchParameters() {
    [
      GraphRequestConnectionState.started,
      .cancelled,
      .completed,
      .serialized,
    ]
      .forEach { state in
        connection.state = state
        assertRaisesException(
          message: "Should raise an exception on request addition when state has raw value: \(state.rawValue)"
        ) {
          self.connection.add(
            self.makeRequestForMeWithEmptyFields(),
            parameters: [:]
          ) { _, _, _ in }
        }
      }
    connection.state = .created

    assertDoesNotRaiseException(
      message: "Should not throw an error on request addition when state is 'created'"
    ) {
      self.connection.add(
        self.makeRequestForMeWithEmptyFields(),
        parameters: [:]
      ) { _, _, _ in }
    }
  }

  func testAddingRequestToBatchWithBatchParameters() throws {
    let batchParameters = [
      name: "Foo",
      "Bar": "Baz",
    ]
    let metadata = GraphRequestMetadata(
      request: makeSampleRequest(),
      completionHandler: nil,
      batchParameters: batchParameters
    )
    let batch = NSMutableArray()
    connection.addRequest(
      metadata,
      toBatch: batch,
      attachments: NSMutableDictionary(),
      batchToken: nil
    )

    let first = batch.firstObject as? [String: String]
    XCTAssertEqual(
      first?[name],
      "Foo",
      "Should add the batch parameters to the from the request to the batch"
    )
    XCTAssertEqual(
      first?["Bar"],
      "Baz",
      "Should add the batch parameters to the from the request to the batch"
    )
  }

  func testAddingRequestToBatchSetsMethod() {
    let postRequest = TestGraphRequest(
      graphPath: "me",
      HTTPMethod: .post
    )
    let metadata = GraphRequestMetadata(
      request: postRequest,
      completionHandler: nil,
      batchParameters: [:]
    )
    let batch = NSMutableArray()
    connection.addRequest(
      metadata,
      toBatch: batch,
      attachments: NSMutableDictionary(),
      batchToken: nil
    )
    let parameters = batch.firstObject as? [String: HTTPMethod]
    XCTAssertEqual(
      parameters?["method"],
      .post,
      "Should include the http method from the graph request in the batch"
    )
  }

  func testAddingRequestToBatchWithToken() throws {
    let token = name
    let expectedItem = URLQueryItem(name: "access_token", value: token)
    let metadata = GraphRequestMetadata(
      request: makeSampleRequest(),
      completionHandler: nil,
      batchParameters: [:]
    )
    let batch = NSMutableArray()
    connection.addRequest(
      metadata,
      toBatch: batch,
      attachments: NSMutableDictionary(),
      batchToken: token
    )
    let parameters = try XCTUnwrap(batch.firstObject as? [String: String])
    let urlString = try XCTUnwrap(parameters["relative_url"])
    let queryItems = try XCTUnwrap(
      URLComponents(string: urlString)?.queryItems
    )
    XCTAssertTrue(
      queryItems.contains(expectedItem),
      "Should include the batch token in the url for the batch request"
    )
  }

  func testAddingRequestToBatchWithAttachments() throws {
    let data = try XCTUnwrap("foo".data(using: .utf8))
    let data2 = try XCTUnwrap("bar".data(using: .utf8))

    let request = makeSampleRequest(parameters: [name: data])
    let request2 = makeSampleRequest(parameters: [name: data2])
    let metadata1 = makeMetadata(from: request)
    let metadata2 = makeMetadata(from: request2)

    let batch = NSMutableArray()
    let attachments = NSMutableDictionary()
    connection.addRequest(
      metadata1,
      toBatch: batch,
      attachments: attachments,
      batchToken: nil
    )
    connection.addRequest(
      metadata2,
      toBatch: batch,
      attachments: attachments,
      batchToken: nil
    )
    batch.enumerateObjects { object, index, _ in
      let expectedFileName = "file\(index)"
      let parameters = object as? [String: String]
      XCTAssertEqual(
        parameters?["attached_files"],
        expectedFileName,
        "Should store retrieval keys for the attachments taken from the graph requests"
      )
    }
    let expectedAttachments = [
      "file0": data,
      "file1": data2,
    ]
    XCTAssertEqual(
      expectedAttachments,
      attachments as? [String: Data],
      "Should add attachments from the graph requests"
    )
  }

  // MARK: - Attachments

  func testAppendingNonFormStringAttachment() {
    let body = TestGraphRequestBody()
    connection.appendAttachments(
      [name: "foo"],
      to: body,
      addFormData: false,
      logger: logger
    )
    XCTAssertNil(
      body.capturedKey,
      "Should not append strings if the attachment type is not form data"
    )
    XCTAssertNil(
      body.capturedFormValue,
      "Should not append strings if the attachment type is not form data"
    )
  }

  func testAppendingFormStringAttachment() {
    let body = TestGraphRequestBody()
    connection.appendAttachments(
      [name: "foo"],
      to: body,
      addFormData: true,
      logger: logger
    )
    XCTAssertEqual(
      body.capturedKey,
      name,
      "Should append strings when the attachment type is form data"
    )
    XCTAssertEqual(body.capturedFormValue, "foo", "Should pass through whether or not to use form data")
  }

  func testAppendingImageData() {
    let image = UIImage()
    let body = TestGraphRequestBody()
    connection.appendAttachments(
      [name: image],
      to: body,
      addFormData: false,
      logger: logger
    )
    XCTAssertEqual(
      body.capturedImage,
      image,
      "Should always append images"
    )

    body.capturedImage = nil
    connection.appendAttachments(
      [name: image],
      to: body,
      addFormData: true,
      logger: logger
    )
    XCTAssertIdentical(
      body.capturedImage,
      image,
      "Should always append images"
    )
  }

  func testAppendingData() {
    let data = name.data(using: .utf8)! // swiftlint:disable:this force_unwrapping
    let body = TestGraphRequestBody()
    connection.appendAttachments(
      [name: data],
      to: body,
      addFormData: false,
      logger: logger
    )
    XCTAssertEqual(
      body.capturedData,
      data,
      "Should always append data"
    )

    body.capturedData = nil
    connection.appendAttachments(
      [name: data],
      to: body,
      addFormData: true,
      logger: logger
    )
    XCTAssertEqual(
      body.capturedData,
      data,
      "Should always append data"
    )
  }

  func testAppendingDataAttachments() {
    let data = name.data(using: .utf8)! // swiftlint:disable:this force_unwrapping
    let attachment = GraphRequestDataAttachment(
      data: data,
      filename: "fooFile",
      contentType: "application/json"
    )
    let body = TestGraphRequestBody()
    connection.appendAttachments(
      [name: attachment],
      to: body,
      addFormData: false,
      logger: logger
    )
    XCTAssertEqual(
      body.capturedAttachment,
      attachment,
      "Should always append data attachments"
    )

    body.capturedAttachment = nil
    connection.appendAttachments(
      [name: attachment],
      to: body,
      addFormData: true,
      logger: logger
    )
    XCTAssertEqual(
      body.capturedAttachment,
      attachment,
      "Should always append data attachments"
    )
  }

  func testAppendingUnknownAttachmentTypeWithLogger() {
    let body = TestGraphRequestBody()
    let logger = makeLogger()
    connection.appendAttachments(
      [name: UIColor.gray],
      to: body,
      addFormData: false,
      logger: logger
    )
    XCTAssertEqual(
      TestLogger.capturedLoggingBehavior,
      .developerErrors,
      "Should log an error when an unsupported type is attached"
    )
    XCTAssertEqual(
      TestLogger.capturedLogEntry,
      "Unsupported FBSDKGraphRequest attachment:UIExtendedGrayColorSpace 0.5 1, skipping.",
      "Should log an error when an unsupported type is attached"
    )
  }

  // MARK: - Cancelling

  func testCancellingConnection() {
    var expectedInvalidationCallCount = 0

    [
      GraphRequestConnectionState.created,
      .started,
      .cancelled,
      .completed,
      .serialized,
    ]
      .forEach { state in
        connection.state = state
        expectedInvalidationCallCount += 1

        connection.cancel()

        XCTAssertEqual(
          connection.state,
          .cancelled,
          "Cancelling a connection should set the state to the expected value"
        )
        XCTAssertEqual(
          session.invalidateAndCancelCallCount,
          expectedInvalidationCallCount,
          "Cancelling a connetion should invalidate and cancel the session"
        )
      }
  }

  // MARK: - Starting

  func testStartingConnectionWithUninitializedSDK() {
    GraphRequestConnection.resetCanMakeRequests()
    connection.logger = makeLogger()

    let expectedMessage = "FBSDKGraphRequestConnection cannot be started before Facebook SDK initialized."
    var capturedError: Error?
    connection.add(makeSampleRequest()) { _, _, error in
      capturedError = error
    }
    connection.start()

    let testError = capturedError as? TestSDKError
    XCTAssertEqual(
      testError?.type,
      .unknown,
      "Starting a graph request before the SDK is initialized should return an unknown-type error"
    )
    XCTAssertEqual(
      testError?.message,
      expectedMessage,
      "Starting a graph request before the SDK is initialized should return an error with the appropriate mesage"
    )

    XCTAssertEqual(
      connection.state,
      .cancelled,
      "Starting a graph request before the SDK is initialized should update the connection state"
    )

    XCTAssertEqual(
      TestLogger.capturedLogEntry,
      expectedMessage,
      "Starting a graph request before the SDK is initialized should log a warning"
    )
    XCTAssertEqual(
      TestLogger.capturedLoggingBehavior,
      .developerErrors,
      "Starting a graph request before the SDK is initialized should log a warning"
    )
  }

  func testStartingWithInvalidStates() {
    connection.logger = makeLogger()

    [
      GraphRequestConnectionState.started,
      .cancelled,
      .completed,
    ]
      .forEach { state in
        connection.state = .created
        connection.add(makeSampleRequest()) { _, _, _ in
          XCTFail("Should not be called")
        }
        connection.state = state
        connection.start()
        XCTAssertEqual(
          connection.state,
          state,
          "Should not change the connection state when starting in an invalid state"
        )
        XCTAssertEqual(
          TestLogger.capturedLogEntry,
          "FBSDKGraphRequestConnection cannot be started again.",
          "Starting a connection in an invalid state"
        )
        XCTAssertEqual(
          TestLogger.capturedLoggingBehavior,
          .developerErrors,
          "Starting a connection in an invalid state"
        )
        XCTAssertNil(session.capturedRequest, "Should not start a request for a connection in an invalid state")
      }
  }

  func testStartingWithValidStates() {
    [
      GraphRequestConnectionState.created,
      .serialized,
    ]
      .forEach { state in
        connection.state = .created
        connection.add(makeSampleRequest()) { _, _, _ in
          XCTFail("Should not be called")
        }
        connection.state = state
        connection.start()
        XCTAssertEqual(
          connection.state,
          .started,
          "Should change the connection state to 'started' when starting in an valid state"
        )
        XCTAssertNotNil(session.capturedRequest, "Should start a request for a connection in an valid state")
      }
  }

  func testStartingWithDelegateQueue() {
    connection.delegate = self
    let queue = TestOperationQueue()
    connection.delegateQueue = queue
    connection.add(makeSampleRequest()) { _, _, _ in
      XCTFail("Should not be called")
    }
    connection.start()
    XCTAssertTrue(
      queue.addOperationWithBlockWasCalled,
      "Starting a connection should add the request to the delegate queue when one exists"
    )
  }

  func testStartingInvokesPiggybackManager() {
    connection.add(makeSampleRequest()) { _, _, _ in }
    connection.start()

    XCTAssertTrue(
      connection === piggybackManager.capturedConnection,
      "Starting a request should invoke the piggyback manager"
    )
  }

  // MARK: - Errors From Results

  func testErrorFromResultWithNonDictionaryInput() {
    let inputs: [Any] = ["foo", 123, true, NSNull(), Data(), [Any]()]

    for input in inputs {
      XCTAssertNil(
        connection.error(fromResult: input, request: makeSampleRequest()),
        "Should not create an error from \(input)"
      )
    }
  }

  func testErrorFromResultWithMissingBodyInInput() {
    XCTAssertNil(
      connection.error(fromResult: [], request: makeSampleRequest()),
      "Should not create an error from an empty dictionary"
    )
  }

  func testErrorFromResultWithMissingErrorInInputBody() {
    let result: [String: Any] = [
      "body": [],
    ]

    XCTAssertNil(
      connection.error(fromResult: result, request: makeSampleRequest()),
      "Should not create an error from a dictionary with a missing error key"
    )
  }

  func testErrorFromResultWithFuzzyInput() {
    (1 ... 100).forEach { _ in
      connection.error(
        fromResult: Fuzzer.randomize(json: makeSampleErrorDictionary()),
        request: makeSampleRequest()
      )
    }
  }

  func testErrorFromResultDependsOnErrorConfiguration() {
    connection.error(
      fromResult: NSDictionary(dictionary: makeSampleErrorDictionary()),
      request: makeSampleRequest()
    )
    let capturedRequest = errorConfiguration.capturedGraphRequest

    XCTAssertNotNil(capturedRequest?.graphPath, "Should capture the graph request from the result")
    XCTAssertEqual(
      errorConfiguration.capturedRecoveryConfigurationCode,
      "1",
      "Should capture the error code from the result"
    )
    XCTAssertEqual(
      errorConfiguration.capturedRecoveryConfigurationSubcode,
      "2",
      "Should capture the error subcode from the result"
    )
  }

  func testErrorFromResult() {
    let error = connection.error(
      fromResult: makeSampleErrorDictionary(),
      request: makeSampleRequest()
    ) as NSError?
    XCTAssertEqual(
      error?.userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String,
      errorRecoveryConfiguration.localizedRecoveryDescription,
      "Should derive the recovery description from the recovery configuration"
    )
    XCTAssertEqual(
      error?.userInfo[NSLocalizedRecoveryOptionsErrorKey] as? [String],
      errorRecoveryConfiguration.localizedRecoveryOptionDescriptions,
      "Should derive the recovery options from the recovery configuration"
    )
    XCTAssertNil(
      error?.userInfo[NSRecoveryAttempterErrorKey],
      "A non transient error should not provide a recovery attempter"
    )
  }

  func testErrorFromResultMessagePriority() {
    var response: [String: Any] = [
      "body": [
        "error": ["error_msg": "error_msg"],
      ],
    ]
    var error = connection.error(
      fromResult: response,
      request: makeSampleRequest()
    ) as? TestSDKError
    XCTAssertEqual(
      error?.message,
      "error_msg",
      "Should use the 'error_msg' if it's the only message available"
    )
    response = [
      "body": [
        "error": [
          "error_msg": "error_msg",
          "error_reason": "error_reason",
        ],
      ],
    ]
    error = connection.error(
      fromResult: response,
      request: makeSampleRequest()
    ) as? TestSDKError
    XCTAssertEqual(
      error?.message,
      "error_reason",
      "Should prefer the 'error_reason' to the 'error_msg'"
    )

    response = [
      "body": [
        "error": [
          "error_msg": "error_msg",
          "error_reason": "error_reason",
          "message": "message",
        ],
      ],
    ]
    error = connection.error(
      fromResult: response,
      request: makeSampleRequest()
    ) as? TestSDKError
    XCTAssertEqual(
      error?.message,
      "message",
      "Should prefer the 'message' key to other error message keys"
    )
  }

  // MARK: - Client Token

  func testClientToken() throws {
    let expectation = XCTestExpectation(description: name)

    errorConfigurationProvider.configuration = nil
    var capturedError: Error?
    connection.add(makeRequestForMeWithEmptyFields()) { _, _, error in
      capturedError = error
      expectation.fulfill()
    }
    connection.start()

    let data = "{\"error\": {\"message\": \"Token is broken\",\"code\": 190,\"error_subcode\": 463, \"type\":\"OAuthException\"}}".data(using: .utf8)! // swiftlint:disable:this force_unwrapping line_length
    let response = HTTPURLResponse(
      url: sampleUrl,
      statusCode: 400,
      httpVersion: nil,
      headerFields: nil
    )

    session.capturedCompletion?(data, response, nil)

    wait(for: [expectation], timeout: 1)

    let error = try XCTUnwrap(capturedError as NSError?)
    // make sure there is no recovery info for client token failures.
    XCTAssertNil(error.localizedRecoverySuggestion)
  }

  func testClientTokenSkipped() throws {
    let expectation = expectation(description: name)
    var capturedError: Error?
    errorConfigurationProvider.configuration = nil
    connection.add(makeRequestForMeWithEmptyFields()) { _, _, error in
      capturedError = error
      expectation.fulfill()
    }
    connection.start()

    let response = HTTPURLResponse(url: sampleUrl, statusCode: 400, httpVersion: nil, headerFields: nil)

    session.capturedCompletion?(missingTokenData, response, nil)
    wait(for: [expectation], timeout: 1)

    let error = try XCTUnwrap(capturedError as NSError?)
    // make sure there is no recovery info for client token failures.
    XCTAssertNil(error.localizedRecoverySuggestion)
  }

  func testConnectionDelegate() {
    let expectation = expectation(description: name)

    var actualCallbacksCount = 0
    connection.add(makeRequestForMeWithEmptyFields()) { _, _, _ in
      XCTAssertEqual(1, actualCallbacksCount, "this should have been the second callback")
      actualCallbacksCount += 1
    }
    connection.add(makeRequestForMeWithEmptyFields()) { _, _, _ in
      XCTAssertEqual(2, actualCallbacksCount, "this should have been the third callback")
      actualCallbacksCount += 1
    }
    requestConnectionStartingCallback = { _ in
      XCTAssertEqual(actualCallbacksCount, 0, "this should have been the first callback")
      actualCallbacksCount += 1
    }
    requestConnectionCallback = { _, error in
      XCTAssertNil(error, "unexpected error: \(String(describing: error))")
      XCTAssertEqual(actualCallbacksCount, 3, "this should have been the fourth callback")
      actualCallbacksCount += 1
      expectation.fulfill()
    }
    connection.delegate = self
    connection.start()

    let meResponse = "{ \"Any\":\"userid\"}".replacingOccurrences(of: "\"", with: "\\\"")
    let responseString = "[{\"code\":200,\"body\": \"\(meResponse)\" }, {\"code\":200,\"body\": \"\(meResponse)\" } ]"
    let data = responseString.data(using: .utf8)
    let response = HTTPURLResponse(url: sampleUrl, statusCode: 200, httpVersion: nil, headerFields: nil)

    session.capturedCompletion?(data, response, nil)

    wait(for: [expectation], timeout: 1)
  }

  func testNonErrorEmptyDictionaryOrNullResponse() {
    let expectation = expectation(description: name)

    var actualCallbacksCount = 0
    connection.add(makeRequestForMeWithEmptyFields()) { _, _, _ in
      XCTAssertEqual(actualCallbacksCount, 1, "this should have been the second callback")
      actualCallbacksCount += 1
    }
    connection.add(makeRequestForMeWithEmptyFields()) { _, _, _ in
      XCTAssertEqual(actualCallbacksCount, 2, "this should have been the third callback")
      actualCallbacksCount += 1
    }
    requestConnectionStartingCallback = { _ in
      XCTAssertEqual(actualCallbacksCount, 0, "this should have been the first callback")
      actualCallbacksCount += 1
    }
    requestConnectionCallback = { _, error in
      XCTAssertNil(error, "unexpected error: \(String(describing: error))")
      XCTAssertEqual(actualCallbacksCount, 3, "this should have been the fourth callback")
      actualCallbacksCount += 1
      expectation.fulfill()
    }
    connection.delegate = self
    connection.start()

    let responseString = "[{\"code\":200,\"body\": null }, {\"code\":200,\"body\": {} } ]"
    let data = responseString.data(using: .utf8)
    let response = HTTPURLResponse(url: sampleUrl, statusCode: 200, httpVersion: nil, headerFields: nil)

    session.capturedCompletion?(data, response, nil)

    wait(for: [expectation], timeout: 1)
  }

  func testConnectionDelegateWithNetworkError() {
    let expectation = expectation(description: name)

    connection.add(makeRequestForMeWithEmptyFields()) { _, _, _ in }
    requestConnectionCallback = { _, error in
      XCTAssertNotNil(error, "didFinishLoading shouldn't have been called")
      expectation.fulfill()
    }
    connection.delegate = self
    connection.start()

    session.capturedCompletion?(nil, nil, NSError(domain: ".domain", code: -1009, userInfo: nil))

    wait(for: [expectation], timeout: 1)
  }

  func testUnsettingAccessToken() {
    let expectation = expectation(description: name)
    let accessToken = AccessToken(
      tokenString: "token",
      permissions: ["public_profile"],
      declinedPermissions: [],
      expiredPermissions: [],
      appID: "appid",
      userID: "userid",
      expirationDate: nil,
      refreshDate: nil,
      dataAccessExpirationDate: nil
    )
    TestAccessTokenWallet.currentAccessToken = accessToken

    connection.add(makeRequest(tokenString: accessToken.tokenString)) { _, result, error in
      XCTAssertNil(result)
      let testError = error as? TestSDKError
      XCTAssertEqual("Token is broken", testError?.message)
      XCTAssertNil(
        TestAccessTokenWallet.currentAccessToken,
        "Should clear the current stored access token"
      )
      expectation.fulfill()
    }
    connection.start()

    let response = HTTPURLResponse(url: sampleUrl, statusCode: 400, httpVersion: nil, headerFields: nil)

    session.capturedCompletion?(missingTokenData, response, nil)

    wait(for: [expectation], timeout: 1)
  }

  func testUnsettingAccessTokenSkipped() {
    let expectation = expectation(description: name)
    TestAccessTokenWallet.currentAccessToken = AccessToken(
      tokenString: "token",
      permissions: ["public_profile"],
      declinedPermissions: [],
      expiredPermissions: [],
      appID: "appid",
      userID: "userid",
      expirationDate: nil,
      refreshDate: nil,
      dataAccessExpirationDate: nil
    )

    let request = TestGraphRequest(
      graphPath: "me",
      parameters: ["fields": ""],
      tokenString: "notCurrentToken"
    )
    connection.add(request) { _, result, error in
      XCTAssertNil(result)
      let testError = error as? TestSDKError
      XCTAssertEqual("Token is broken", testError?.message)
      XCTAssertNotNil(TestAccessTokenWallet.currentAccessToken)
      expectation.fulfill()
    }
    connection.start()

    let response = HTTPURLResponse(url: sampleUrl, statusCode: 400, httpVersion: nil, headerFields: nil)

    session.capturedCompletion?(missingTokenData, response, nil)

    wait(for: [expectation], timeout: 1)
  }

  func testUnsettingAccessTokenFlag() {
    let expectation = expectation(description: name)
    TestAccessTokenWallet.currentAccessToken = AccessToken(
      tokenString: "token",
      permissions: ["public_profile"],
      declinedPermissions: [],
      expiredPermissions: [],
      appID: "appid",
      userID: "userid",
      expirationDate: nil,
      refreshDate: nil,
      dataAccessExpirationDate: nil
    )

    let request = TestGraphRequest(
      graphPath: "me",
      parameters: ["fields": ""],
      flags: [.doNotInvalidateTokenOnError]
    )
    connection.add(request) { _, result, error in
      XCTAssertNil(result)
      let testError = error as? TestSDKError
      XCTAssertEqual("Token is broken", testError?.message)
      XCTAssertNotNil(TestAccessTokenWallet.currentAccessToken)
      expectation.fulfill()
    }
    connection.start()

    let response = HTTPURLResponse(url: sampleUrl, statusCode: 400, httpVersion: nil, headerFields: nil)

    session.capturedCompletion?(missingTokenData, response, nil)

    wait(for: [expectation], timeout: 1)
  }

  func testRequestWithUserAgentSuffix() throws {
    settings.userAgentSuffix = "UnitTest.1.0.0"

    connection.add(makeRequestForMeWithEmptyFields()) { _, _, _ in }
    connection.start()

    let userAgent = try XCTUnwrap(session.capturedRequest?.value(forHTTPHeaderField: "User-Agent"))
    XCTAssertTrue(userAgent.hasSuffix("/UnitTest.1.0.0"), "unexpected user agent \(userAgent)")
  }

  func testRequestWithoutUserAgentSuffix() throws {
    settings.userAgentSuffix = nil

    connection.add(makeRequestForMeWithEmptyFields()) { _, _, _ in }
    connection.start()

    let userAgent = try XCTUnwrap(session.capturedRequest?.value(forHTTPHeaderField: "User-Agent"))
    XCTAssertEqual(
      userAgent,
      "FBiOSSDK.\(FBSDK_VERSION_STRING)",
      "unexpected user agent \(userAgent)"
    )
  }

  func testRequestWithMacCatalystUserAgent() throws {
    macCatalystDeterminator.stubbedIsMacCatalystApp = true
    settings.userAgentSuffix = nil

    connection.add(makeRequestForMeWithEmptyFields()) { _, _, _ in }
    connection.start()

    let userAgent = try XCTUnwrap(session.capturedRequest?.value(forHTTPHeaderField: "User-Agent"))
    XCTAssertTrue(userAgent.hasSuffix("/macOS"), "unexpected user agent \(userAgent)")
  }

  func testNonDictionaryInError() {
    let expectation = expectation(description: name)

    connection.add(makeRequestForMeWithEmptyFields()) { _, _, _ in
      // should not crash when receiving something other than a dictionary within the response.
      expectation.fulfill()
    }
    connection.start()

    let data = "{\"error\": \"a-non-dictionary\"}".data(using: .utf8)
    let response = HTTPURLResponse(url: sampleUrl, statusCode: 200, httpVersion: nil, headerFields: nil)

    session.capturedCompletion?(data, response, nil)

    wait(for: [expectation], timeout: 1)
  }

  func testRequestWithBatchConstructionWithSingleGetRequest() throws {
    let singleRequest = TestGraphRequest(graphPath: "me", parameters: ["fields": "with_suffix"])
    connection.add(singleRequest) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    let requestBody = try XCTUnwrap(request.httpBody)

    XCTAssertEqual(urlComponents.host, "graph.facebook.com")
    XCTAssertTrue(urlComponents.path.contains("me"))
    XCTAssertEqual(request.httpMethod, "GET")
    XCTAssertEqual(requestBody.count, 0)
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
  }

  func testRequestWithBatchConstructionWithSinglePostRequest() throws {
    // T108100329: Abstract internal utility from GraphRequestConnection
    AuthenticationToken.current = nil

    let parameters: [String: Any] = [
      "first_key": "first_value",
    ]
    let singleRequest = TestGraphRequest(graphPath: "activities", parameters: parameters, HTTPMethod: .post)
    connection.add(singleRequest) { _, _, _ in }
    let requests = try XCTUnwrap(connection.requests as? [GraphRequestMetadata])
    let request = connection.request(withBatch: requests, timeout: 0)

    let url = try XCTUnwrap(request.url)
    let urlComponents = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: true))
    let requestBody = try XCTUnwrap(request.httpBody)

    XCTAssertEqual(urlComponents.host, "graph.facebook.com")
    XCTAssertTrue(urlComponents.path.contains("activities"))
    XCTAssertEqual(request.httpMethod, "POST")
    XCTAssertGreaterThan(requestBody.count, 0)
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Encoding"), "gzip")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
  }

  // MARK: - accessTokenWithRequest

  func testAccessTokenWithRequest() {
    // T108100329: Abstract internal utility from GraphRequestConnection
    AuthenticationToken.current = nil

    let expectedToken = "fake_token"
    let request = TestGraphRequest(
      graphPath: "me",
      parameters: ["fields": ""],
      tokenString: expectedToken,
      HTTPMethod: .get,
      flags: []
    )
    let token = connection.accessToken(with: request)
    XCTAssertEqual(token, expectedToken)
  }

  func testAccessTokenWithRequestWithoutFacebookClientToken() throws {
    settings.clientToken = nil
    connection.logger = makeLogger()

    assertRaisesException(message: "An exception should be raised if a client token is unavailable") {
      self.connection.accessToken(with: self.makeRequestForMeWithEmptyFieldsNoTokenString())
    }

    XCTAssertEqual(
      TestLogger.capturedLoggingBehavior,
      .developerErrors,
      "Should log a developer error when a request is started with no client token set"
    )

    let message = try XCTUnwrap(TestLogger.capturedLogEntry)
    XCTAssertTrue(
      message.starts(with: "Starting with v13 of the SDK, a client token must be embedded in your client code"),
      "Should log the expected error message when a request is started with no client token set"
    )

    TestLogger.reset()

    assertRaisesException(message: "An exception should be raised if a client token is unavailable") {
      self.connection.accessToken(with: self.makeRequestForMeWithEmptyFieldsNoTokenString())
    }

    XCTAssertEqual(
      TestLogger.capturedLoggingBehavior,
      .developerErrors,
      "Should log consistently for requests started with no client token set"
    )
  }

  func testAccessTokenWithRequestWithFacebookClientToken() {
    connection.logger = makeLogger()
    let token = connection.accessToken(with: makeRequestForMeWithEmptyFieldsNoTokenString())

    let expectedToken = "\(appID)|\(clientToken)"
    XCTAssertEqual(token, expectedToken)

    XCTAssertNil(
      TestLogger.capturedLoggingBehavior,
      "Should not log a developer error when a request is started with a client token set"
    )
  }

  func testAccessTokenWithRequestWithGamingClientToken() {
    settings.clientToken = clientToken
    let authToken = AuthenticationToken(
      tokenString: "token_string",
      nonce: "nonce",
      graphDomain: "gaming"
    )
    TestAuthenticationTokenWallet.currentAuthenticationToken = authToken
    let token = connection.accessToken(with: makeRequestForMeWithEmptyFieldsNoTokenString())

    let expectedToken = "GG|\(appID)|\(clientToken)"
    XCTAssertEqual(token, expectedToken)
  }

  // MARK: - Error recovery.

  func testRetryWithTransientError() throws {
    let expectation = expectation(description: name)

    settings.isGraphErrorRecoveryEnabled = true

    errorRecoveryConfiguration = makeTransientErrorRecoveryConfiguration()
    errorConfiguration.stubbedRecoveryConfiguration = errorRecoveryConfiguration
    errorConfigurationProvider.configuration = errorConfiguration
    let retryConnection = GraphRequestConnection()
    graphRequestConnectionFactory.stubbedConnection = retryConnection

    var completionCallCount = 0
    var capturedError: Error?
    connection.add(makeRequestForMeWithEmptyFields()) { _, _, error in
      completionCallCount += 1
      XCTAssertEqual(completionCallCount, 1, "The completion should only be called once")
      capturedError = error
      expectation.fulfill()
    }

    connection.start()

    let data = "{\"error\": {\"message\": \"Server is busy\",\"code\": 1,\"error_subcode\": 463}}".data(using: .utf8)
    let response = HTTPURLResponse(url: sampleUrl, statusCode: 400, httpVersion: nil, headerFields: nil)

    // The first captured completion will be invoked and cause the retry
    session.capturedCompletion?(data, response, nil)

    // It's necessary to dispatch async to avoid the completion from being invoked before it is captured
    DispatchQueue.main.async {
      let secondData = "{\"error\": {\"message\": \"Server is busy\",\"code\": 2,\"error_subcode\": 463}}".data(using: .utf8) // swiftlint:disable:this line_length
      self.secondSession.capturedCompletion?(secondData, response, nil)
    }

    wait(for: [expectation], timeout: 1)

    let error = try XCTUnwrap(capturedError as NSError?)
    XCTAssertEqual(
      2,
      error.userInfo[GraphRequestErrorGraphErrorCodeKey] as? Int,
      "The completion should be called with the expected error code"
    )
  }

  func testRetryDisabled() throws {
    settings.isGraphErrorRecoveryEnabled = false

    let expectation = expectation(description: name)

    var completionCallCount = 0
    var capturedError: Error?
    connection.add(makeRequestForMeWithEmptyFields()) { _, _, error in
      capturedError = error
      completionCallCount += 1
      XCTAssertEqual(completionCallCount, 1, "The completion should only be called once")
      expectation.fulfill()
    }

    connection.start()

    let data = "{\"error\": {\"message\": \"Server is busy\",\"code\": 1,\"error_subcode\": 463}}".data(using: .utf8)
    let response = HTTPURLResponse(url: sampleUrl, statusCode: 400, httpVersion: nil, headerFields: nil)

    // The first captured completion will be invoked and cause the retry
    session.capturedCompletion?(data, response, nil)

    wait(for: [expectation], timeout: 1)

    let error = try XCTUnwrap(capturedError as NSError?)
    XCTAssertEqual(
      1,
      error.userInfo[GraphRequestErrorGraphErrorCodeKey] as? Int,
      "The completion should be called with the expected error code"
    )
  }

  // MARK: - Response Parsing

  func testParsingJsonResponseWithInvalidData() {
    var value = 0xb70f
    let data = Data(bytes: &value, count: 2)
    var error: NSError?
    connection.parseJSONResponse(data, error: &error, statusCode: 0)

    XCTAssertEqual(
      eventLogger.capturedEventName?.rawValue,
      "fb_response_invalid_utf8",
      "Should log the correct event name"
    )
    XCTAssertTrue(
      eventLogger.capturedIsImplicitlyLogged,
      "Should implicitly log an event indicating a json parsing failure"
    )
  }

  func testProcessingResultBodyWithDebugDictionary() {
    connection.logger = makeLogger()
    let entries = [
      "message1 Link: link1",
      "message2 Link: link2",
    ]
    connection.processResultBody(debugResponse, error: nil, metadata: metadata, canNotifyDelegate: false)
    XCTAssertEqual(
      TestLogger.capturedLogEntries,
      entries,
      "Should log entries from the debug dictionary"
    )
  }

  func testProcessingResultBodyWithRandomizedDebugDictionary() {
    (1 ..< 100).forEach { _ in
      if let body = Fuzzer.randomize(json: debugResponse) as? [String: Any] {
        connection.processResultBody(body, error: nil, metadata: metadata, canNotifyDelegate: false)
      }
    }
  }

  func testLogRequestWithInactiveLogger() {
    let request = NSMutableURLRequest(url: sampleUrl)
    let logger = makeLogger()
    let bodyLogger = makeLogger()
    let attachmentLogger = makeLogger()
    connection.logger = logger
    connection.logRequest(request, bodyLength: 1024, bodyLogger: bodyLogger, attachmentLogger: attachmentLogger)

    XCTAssertEqual(logger.capturedAppendedKeys, [])
    XCTAssertEqual(logger.capturedAppendedValues, [])
  }

  func testLogRequestWithActiveLogger() {
    let request = NSMutableURLRequest(url: sampleUrl)
    request.addValue("user agent", forHTTPHeaderField: "User-Agent")
    request.addValue("content type", forHTTPHeaderField: "Content-Type")
    let logger = makeLogger()
    let bodyLogger = makeLogger()
    let attachmentLogger = makeLogger()

    // Start with some previously 'logged' contents
    bodyLogger.capturedContents = "bodyContents"
    attachmentLogger.capturedContents = "attachmentLoggerContents"
    logger.stubbedIsActive = true
    connection.logger = logger

    connection.logRequest(request, bodyLength: 1024, bodyLogger: bodyLogger, attachmentLogger: attachmentLogger)

    let expectedKeys = [
      "URL",
      "Method",
      "UserAgent",
      "MIME",
      "Body Size",
      "Body (w/o attachments)",
      "Attachments",
    ]

    let expectedValues = [
      "https://example.com",
      "GET",
      "user agent",
      "content type",
      "1 kB",
      "bodyContents",
      "attachmentLoggerContents",
    ]

    XCTAssertEqual(
      logger.capturedAppendedKeys,
      expectedKeys,
      "Should append the expected key value pairs to log"
    )
    XCTAssertEqual(
      logger.capturedAppendedValues,
      expectedValues,
      "Should append the expected key value pairs to log"
    )
  }

  func testInvokesDelegate() {
    connection.delegate = self
    connection.urlSession(
      URLSession.shared,
      task: URLSessionDataTask(),
      didSendBodyData: 0,
      totalBytesSent: 0,
      totalBytesExpectedToSend: 0
    )

    XCTAssertTrue(
      didInvokeDelegateRequestConnectionDidSendBodyData,
      "The url session data delegate should pass through to the graph request connection delegate"
    )
  }

  // MARK: - Helpers

  func makeLogger() -> TestLogger {
    TestLogger(loggingBehavior: .developerErrors)
  }

  func makeSampleRequest() -> TestGraphRequest {
    makeRequestForMeWithEmptyFields()
  }

  func makeSampleRequest(parameters: [String: Any]) -> TestGraphRequest {
    TestGraphRequest(graphPath: "me", parameters: parameters)
  }

  func makeRequestForMeWithEmptyFields() -> TestGraphRequest {
    TestGraphRequest(graphPath: "me", parameters: ["fields": ""])
  }

  func makeRequestForMeWithEmptyFieldsNoTokenString() -> TestGraphRequest {
    TestGraphRequest(
      graphPath: "me",
      parameters: ["fields": ""],
      flags: []
    )
  }

  func makeRequest(tokenString: String) -> TestGraphRequest {
    TestGraphRequest(
      graphPath: "me",
      parameters: ["fields": ""],
      tokenString: tokenString
    )
  }

  func makeMetadata(from request: GraphRequestProtocol) -> GraphRequestMetadata {
    GraphRequestMetadata(
      request: request,
      completionHandler: nil,
      batchParameters: [:]
    )
  }

  func makeSampleErrorDictionary() -> [String: Any] {
    [
      "code": 200,
      "body": [
        "error": [
          "is_transient": 1,
          "code": 1,
          "error_subcode": 2,
          "error_msg": "error_msg",
          "error_reason": "error_reason",
          "message": "message",
          "error_user_title": "error_user_title",
          "error_user_msg": "error_user_msg",
        ],
      ],
    ]
  }

  func makeTransientErrorRecoveryConfiguration() -> ErrorRecoveryConfiguration {
    ErrorRecoveryConfiguration(
      recoveryDescription: "Recovery Description",
      optionDescriptions: ["Option1", "Option2"],
      category: .transient,
      recoveryActionName: "Recovery Action"
    )
  }

  func makeNonTransientErrorRecoveryConfiguration() -> ErrorRecoveryConfiguration {
    ErrorRecoveryConfiguration(
      recoveryDescription: "Recovery Description",
      optionDescriptions: ["Option1", "Option2"],
      category: .other,
      recoveryActionName: "Recovery Action"
    )
  }

  var debugResponse: [String: Any] {
    [
      "__debug__": [
        "messages": [
          [
            "message": "message1",
            "type": "type1",
            "link": "link1",
          ],
          [
            "message": "message2",
            "type": "warning",
            "link": "link2",
          ],
        ],
      ],
    ]
  }
}
