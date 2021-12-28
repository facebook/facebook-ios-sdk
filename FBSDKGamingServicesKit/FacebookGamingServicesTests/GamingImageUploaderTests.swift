/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookGamingServices
import TestTools
import XCTest

class GamingImageUploaderTests: XCTestCase {

  let factory = TestGamingServiceControllerFactory()
  let connection = TestGraphRequestConnection()
  let graphConnectionFactory = TestGraphRequestConnectionFactory()
  lazy var uploader = GamingImageUploader(
    gamingServiceControllerFactory: factory,
    graphRequestConnectionFactory: graphConnectionFactory
  )
  lazy var configuration = createConfiguration(shouldLaunch: true)

  override func setUp() {
    super.setUp()

    AccessToken.current = SampleAccessTokens.validToken
    graphConnectionFactory.stubbedConnection = connection
  }

  override func tearDown() {
    AccessToken.current = nil

    super.tearDown()
  }

  // MARK: - Dependencies

  func testDefaultDependencies() {
    XCTAssertTrue(
      GamingImageUploader.shared.factory is _GamingServiceControllerFactory,
      "Should use the expected default gaming service controller factory"
    )
    XCTAssertTrue(
      GamingImageUploader.shared.graphRequestConnectionFactory is GraphRequestConnectionFactory,
      "Should use the expected default graph request connection factory"
    )
  }

  func testCustomDependencies() {
    XCTAssertTrue(
      uploader.factory is TestGamingServiceControllerFactory,
      "Should use the expected gaming service controller factory"
    )
    XCTAssertTrue(
      uploader.graphRequestConnectionFactory is TestGraphRequestConnectionFactory,
      "Should use the expected graph request connection factory"
    )
  }

  // MARK: - Configuration

  func testValuesAreSavedToConfiguration() throws {
    let image = createSampleUIImage()
    let configuration = GamingImageUploaderConfiguration(
      image: image,
      caption: "Cool Photo",
      shouldLaunchMediaDialog: true
    )

    XCTAssertEqual(configuration.caption, "Cool Photo")
    XCTAssertEqual(configuration.image.pngData(), image.pngData())
    XCTAssertTrue(configuration.shouldLaunchMediaDialog)
  }

  // MARK: - Uploading

  func testFailureWhenNoValidAccessTokenPresent() {
    AccessToken.current = nil

    var wasCompletionCalled = false
    uploader.uploadImage(with: configuration) { _, _, error in
      XCTAssertEqual(
        (error as NSError?)?.code,
        CoreError.errorAccessTokenRequired.rawValue,
        "Expected error requiring a valid access token"
      )
      wasCompletionCalled = true
    }

    XCTAssertTrue(wasCompletionCalled)
  }

  func testGraphErrorsAreHandled() throws {
    var wasCompletionCalled = false
    uploader.uploadImage(with: configuration) { success, results, error in
      XCTAssertFalse(success)
      XCTAssertNil(results)
      XCTAssertEqual(
        (error as NSError?)?.code,
        CoreError.errorGraphRequestGraphAPI.rawValue,
        "Should indicate that the error was related to the graph request"
      )
      wasCompletionCalled = true
    }

    let completion = try XCTUnwrap(
      (graphConnectionFactory.stubbedConnection as? TestGraphRequestConnection)?.capturedCompletion
    )
    completion(nil, nil, SampleError())

    XCTAssertTrue(wasCompletionCalled)
  }

  func testGraphResponsesTriggerCompletionIfDialogNotRequested() throws {
    let expectedID = "111"
    let expectedResult = ["id": expectedID]
    let expectedDialogResult = [String: String]()
    let expectedError = NSError(domain: CoreError.errorDomain, code: CoreError.errorUnknown.rawValue, userInfo: nil)

    var wasCompletionInvoked = false
    uploader.uploadImage(with: configuration) { success, result, error in
      XCTAssertTrue(success)
      XCTAssertEqual(error as NSError?, expectedError)
      XCTAssertEqual(result as? [String: String], expectedDialogResult)
      wasCompletionInvoked = true
    }

    let completion = try XCTUnwrap(
      (graphConnectionFactory.stubbedConnection as? TestGraphRequestConnection)?.capturedCompletion
    )
    completion(nil, expectedResult, nil)

    factory.capturedCompletion(true, [:], expectedError)

    XCTAssertEqual(
      factory.capturedServiceType,
      .mediaAsset,
      "Should create a controller with the expected service type"
    )
    XCTAssertEqual(
      factory.capturedPendingResult as? [String: String],
      expectedResult,
      "Should create a controller with a pending result"
    )
    XCTAssertEqual(
      factory.controller.capturedArgument,
      expectedID,
      "Should invoke the new controller with the id from the result"
    )

    XCTAssertTrue(wasCompletionInvoked)
  }

  func testGraphResponsesDoNotTriggerCompletionIfDialogIsRequested() throws {
    var wasCompletionInvoked = false
    uploader.uploadImage(with: configuration) { _, _, _ in
      wasCompletionInvoked = true
    }

    let completion = try XCTUnwrap(
      (graphConnectionFactory.stubbedConnection as? TestGraphRequestConnection)?.capturedCompletion
    )
    completion(nil, ["id": "123"], nil)

    XCTAssertFalse(
      wasCompletionInvoked,
      "Callback should not have been called because there was more work to do"
    )
  }

  func testGraphResponsesTriggerDialogIfDialogIsRequested() throws {
    let expectedID = "111"
    let expectedResult = ["id": expectedID]

    var didInvokeCompletion = false
    uploader.uploadImage(with: configuration) { _, _, _ in
      didInvokeCompletion = true
    }

    let completion = try XCTUnwrap(
      (graphConnectionFactory.stubbedConnection as? TestGraphRequestConnection)?.capturedCompletion
    )
    completion(nil, expectedResult, nil)

    XCTAssertFalse(
      didInvokeCompletion,
      "Should not invoke the completion because a dialog is launched instead"
    )

    XCTAssertEqual(
      factory.capturedServiceType,
      .mediaAsset,
      "Should create a controller with the expected service type"
    )
    XCTAssertEqual(
      factory.capturedPendingResult as? [String: String],
      expectedResult,
      "Should not create a controller with a pending result"
    )
    XCTAssertEqual(
      factory.controller.capturedArgument,
      expectedID,
      "Should invoke the new controller with the id from the result"
    )

    factory.capturedCompletion(true, nil, nil)

    XCTAssertTrue(didInvokeCompletion)
  }

  func testUploadProgress() throws {
    let expectedResult = ["id": "foo"]
    var wasCompletionInvoked = false
    var wasProgressHandlerInvoked = false
    uploader.uploadImage(
      with: configuration,
      completion: { success, result, error in
        XCTAssertTrue(success)
        XCTAssertEqual(
          result?["id"] as? String,
          expectedResult["id"]
        )
        XCTAssertNil(error)
        wasCompletionInvoked = true
      },
      andProgressHandler: { bytesSent, totalBytesSent, totalBytesExpectedToSend in
        XCTAssertEqual(bytesSent, 123)
        XCTAssertEqual(totalBytesSent, 456)
        XCTAssertEqual(totalBytesExpectedToSend, 789)
        wasProgressHandlerInvoked = true
      }
    )

    connection.delegate?.requestConnection?(
      connection,
      didSendBodyData: 123,
      totalBytesWritten: 456,
      totalBytesExpectedToWrite: 789
    )
    XCTAssertTrue(wasProgressHandlerInvoked)

    let completion = try XCTUnwrap(
      (graphConnectionFactory.stubbedConnection as? TestGraphRequestConnection)?.capturedCompletion
    )
    completion(nil, expectedResult, nil)
    factory.capturedCompletion(true, expectedResult, nil)

    XCTAssertTrue(wasCompletionInvoked)
  }

  // MARK: - Helpers

  func createSampleUIImage() -> UIImage {
    UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
    UIColor.red.setFill()
    UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return image! // swiftlint:disable:this force_unwrapping
  }

  func createConfiguration(shouldLaunch: Bool) -> GamingImageUploaderConfiguration {
    GamingImageUploaderConfiguration(
      image: createSampleUIImage(),
      caption: "Cool Photo",
      shouldLaunchMediaDialog: shouldLaunch
    )
  }
}
