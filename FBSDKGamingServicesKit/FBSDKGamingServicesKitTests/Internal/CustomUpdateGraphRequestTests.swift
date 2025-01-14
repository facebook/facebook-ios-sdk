/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit

import FBSDKCoreKit
import TestTools
import XCTest

@available(iOS 13.0, *)
final class CustomUpdateGraphRequestTests: XCTestCase {
  let factory = TestGraphRequestFactory()
  lazy var requester = CustomUpdateGraphRequest(graphRequestFactory: factory)
  var validContextTokenID = "12345"

  let validMediaContentParameterDictionary = [
    CustomUpdateContentObjectsParameters.contextKEY: CustomUpdateContentObjectsParameters.contextValue,
    CustomUpdateContentObjectsParameters.textKey: CustomUpdateContentObjectsParameters.textValue,
    CustomUpdateContentObjectsParameters.mediaKey: CustomUpdateContentObjectsParameters.mediaValue,
  ]

  let validImageContentParameterDictionary = [
    CustomUpdateContentObjectsParameters.contextKEY: CustomUpdateContentObjectsParameters.contextValue,
    CustomUpdateContentObjectsParameters.textKey: CustomUpdateContentObjectsParameters.textValue,
    CustomUpdateContentObjectsParameters.imageKey: "data:image/png;base64,\(CustomUpdateContentObjects.validImage.pngData()!.base64EncodedString())", // swiftlint:disable:this force_unwrapping
  ]

  override func setUp() {
    super.setUp()
    GamingContext.current = GamingContext(identifier: validContextTokenID, size: 0)
    AuthenticationToken.current = SampleAuthenticationToken.validToken(withGraphDomain: "gaming")
  }

  func testDependencies() {
    let requester = CustomUpdateGraphRequest()
    XCTAssertTrue(
      requester.graphRequestFactory is GraphRequestFactory,
      "Should have a default GraphRequestFactory of the expected type"
    )
  }

  func testCustomDependencies() {
    XCTAssertIdentical(
      requester.graphRequestFactory as AnyObject,
      factory,
      "Should be able to create with a custom graph request factory"
    )
  }

  // MARK: - CustomUpdateContentMedia

  func testPerformRequest() throws {
    try requester.request(content: CustomUpdateContentObjects.mediaContentValid) { _ in
      XCTFail("Should not reach here")
    }

    let request = try XCTUnwrap(factory.capturedRequests.first)

    XCTAssertEqual(
      request.startCallCount,
      1,
      "Should start the custom update request"
    )
    XCTAssertEqual(
      factory.capturedGraphPath,
      "me/custom_update",
      "Should create a request with the expected graph path"
    )
//    XCTAssertEqual(
//      factory.capturedParameters as? [String: String],
//      validMediaContentParameterDictionary,
//      "Request should have the correct parameters"
//    )
  }

  func testHandlingRequestInvalidMediaContentError() throws {
    var caughtContentError = false
    do {
      try requester.request(content: CustomUpdateContentObjects.mediaContentInvalidMessage) { _ in
        XCTFail("Should not succeed")
      }
    } catch CustomUpdateContentError.invalidMessage {
      caughtContentError = true
    }

    XCTAssertTrue(caughtContentError, "Should throw an invalid message content error")
  }

  func testHandlingRequestError() throws {
    var completionWasInvoked = false
    try requester.request(content: CustomUpdateContentObjects.mediaContentValid) { result in
      switch result {
      case let .failure(error):
        guard case let .server(serverError) = error else {
          return XCTFail("Should not be a decoding error")
        }
        XCTAssertTrue(serverError is SampleError)
      case .success:
        XCTFail("Should not succeed")
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, nil, SampleError())

    XCTAssert(completionWasInvoked)
  }

  func testHandlingRequestInvalidResult() throws {
    var completionWasInvoked = false
    try requester.request(content: CustomUpdateContentObjects.mediaContentValid) { result in
      switch result {
      case let .failure(error):
        guard case .decoding = error else {
          return XCTFail(
            "Expected a decoding error, instead received: \(error)"
          )
        }
      case .success:
        XCTFail("Should not succeed")
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, SampleCustomUpdateGraphAPIResults.invalid, nil)

    XCTAssert(completionWasInvoked)
  }

  func testHandlingRequestSuccessFalse() throws {
    var completionWasInvoked = false
    var didSucceed = false

    try requester.request(content: CustomUpdateContentObjects.mediaContentValid) { result in
      switch result {
      case let .failure(error):
        return XCTFail(
          "Expecting the request to succeed instead receieved: \(error)"
        )
      case let .success(succeed):
        didSucceed = succeed
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, SampleCustomUpdateGraphAPIResults.successFalse, nil)

    XCTAssert(completionWasInvoked)
    XCTAssertFalse(didSucceed)
  }

  func testHandlingRequestValidResult() throws {
    var completionWasInvoked = false
    var didSucceed = false

    try requester.request(content: CustomUpdateContentObjects.mediaContentValid) { result in
      switch result {
      case let .failure(error):
        return XCTFail(
          "Expecting the request to succeed instead receieved: \(error)"
        )
      case let .success(succeed):
        didSucceed = succeed
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, SampleCustomUpdateGraphAPIResults.successTrue, nil)

    XCTAssert(completionWasInvoked)
    XCTAssertTrue(didSucceed)
  }

  // MARK: - CustomUpdateContentImage

  func testPerformRequestWithImageContent() throws {
    try requester.request(content: CustomUpdateContentObjects.imageContentValid) { _ in
      XCTFail("Should not reach here")
    }

    let request = try XCTUnwrap(factory.capturedRequests.first)

    XCTAssertEqual(
      request.startCallCount,
      1,
      "Should start the custom update request"
    )
    XCTAssertEqual(
      factory.capturedGraphPath,
      "me/custom_update",
      "Should create a request with the expected graph path"
    )
    // TODO: Fix this test
//    XCTAssertEqual(
//      factory.capturedParameters as? [String: String],
//      validImageContentParameterDictionary,
//      "Request should have the correct parameters"
//    )
  }

  func testHandlingRequestInvalidImageContentError() throws {
    var caughtContentError = false
    do {
      try requester.request(content: CustomUpdateContentObjects.imageContentInvalidImage) { _ in
        XCTFail("Should not reach here")
      }
    } catch CustomUpdateContentError.invalidImage {
      caughtContentError = true
    }

    XCTAssertTrue(caughtContentError, "Should throw an invalid image content error")
  }

  func testHandlingRequestErrorWithImageContent() throws {
    var completionWasInvoked = false
    try requester.request(content: CustomUpdateContentObjects.imageContentValid) { result in
      switch result {
      case let .failure(error):
        guard case let .server(serverError) = error else {
          return XCTFail("Should not be a decoding error")
        }
        XCTAssertTrue(serverError is SampleError)
      case .success:
        XCTFail("Should not succeed")
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, nil, SampleError())

    XCTAssert(completionWasInvoked)
  }

  func testHandlingRequestInvalidResultWithImageContent() throws {
    var completionWasInvoked = false
    try requester.request(content: CustomUpdateContentObjects.imageContentValid) { result in
      switch result {
      case let .failure(error):
        guard case .decoding = error else {
          return XCTFail(
            "Expected a decoding error, instead received: \(error)"
          )
        }
      case .success:
        XCTFail("Should not succeed")
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, SampleCustomUpdateGraphAPIResults.invalid, nil)

    XCTAssert(completionWasInvoked)
  }

  func testHandlingRequestSuccessFalseWithImageContent() throws {
    var completionWasInvoked = false
    var didSucceed = false

    try requester.request(content: CustomUpdateContentObjects.imageContentValid) { result in
      switch result {
      case let .failure(error):
        return XCTFail(
          "Expecting the request to succeed instead receieved: \(error)"
        )
      case let .success(succeed):
        didSucceed = succeed
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, SampleCustomUpdateGraphAPIResults.successFalse, nil)

    XCTAssert(completionWasInvoked)
    XCTAssertFalse(didSucceed)
  }

  func testHandlingRequestValidResultWithImageContent() throws {
    var completionWasInvoked = false
    var didSucceed = false

    try requester.request(content: CustomUpdateContentObjects.imageContentValid) { result in
      switch result {
      case let .failure(error):
        return XCTFail(
          "Expecting the request to succeed instead receieved: \(error)"
        )
      case let .success(succeed):
        didSucceed = succeed
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, SampleCustomUpdateGraphAPIResults.successTrue, nil)

    XCTAssert(completionWasInvoked)
    XCTAssertTrue(didSucceed)
  }

  enum SampleCustomUpdateGraphAPIResults {
    static let successTrue = ["success": 1]
    static let successFalse = ["success": 0]
    static let invalid = ["not_success": "value"]
  }
}
