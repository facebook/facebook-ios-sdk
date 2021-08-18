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

import FacebookGamingServices

#if FBSDK_SWIFT_PACKAGE
import FacebookCore
#else
import FBSDKCoreKit
#endif

import TestTools
import XCTest

@available(iOS 13.0, *)
class CustomUpdateGraphRequestTests: XCTestCase {
  let factory = TestGraphRequestFactory()
  lazy var requester = CustomUpdateGraphRequest(graphRequestFactory: factory)
  let validMediaContentParameterDictionary = [
    CustomUpdateContentObjectsParameters.contextKEY: CustomUpdateContentObjectsParameters.contextValue,
    CustomUpdateContentObjectsParameters.textKey: CustomUpdateContentObjectsParameters.textValue,
    CustomUpdateContentObjectsParameters.mediaKey: CustomUpdateContentObjectsParameters.mediaValue
  ]

  let validImageContentParameterDictionary = [
    CustomUpdateContentObjectsParameters.contextKEY: CustomUpdateContentObjectsParameters.contextValue,
    CustomUpdateContentObjectsParameters.textKey: CustomUpdateContentObjectsParameters.textValue,
    CustomUpdateContentObjectsParameters.imageKey: CustomUpdateContentObjectsParameters.imageValue
  ]

  func testDependencies() {
    let requester = CustomUpdateGraphRequest()
    XCTAssertTrue(
      requester.graphRequestFactory is GraphRequestFactory,
      "Should have a default GraphRequestFactory of the expected type"
    )
  }

  func testCustomDependencies() {
    XCTAssertEqual(
      requester.graphRequestFactory as? TestGraphRequestFactory,
      factory,
      "Should be able to create with a custom graph request factory"
    )
  }
  // MARK: - CustomUpdateContentMedia

  func testPerformRequest() throws {
    try requester.request(content: CustomUpdateContentObjects.mediaContentValid()) { _ in
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
    XCTAssertEqual(
      factory.capturedParameters as? [String: String],
      validMediaContentParameterDictionary,
      "Request should have the correct parameters"
    )
  }

  func testHandlingRequestInvalidMediaContentError() throws {
    try requester.request(content: CustomUpdateContentObjects.mediaContentInvalidContextID()) { result in
      switch result {
      case .failure(let error):
        guard case .contentParsing = error else {
          return XCTFail("Should not be a decoding error")
        }
      case .success:
        XCTFail("Should not succeed")
      }
    }
  }

  func testHandlingRequestError() throws {
    var completionWasInvoked = false
    try requester.request(content: CustomUpdateContentObjects.mediaContentValid()) { result in
      switch result {
      case .failure(let error):
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
    try requester.request(content: CustomUpdateContentObjects.mediaContentValid()) { result in
      switch result {
      case .failure(let error):
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

    try requester.request(content: CustomUpdateContentObjects.mediaContentValid()) { result in
      switch result {
      case .failure(let error):
        return XCTFail(
          "Expecting the request to succeed instead receieved: \(error)"
        )
      case .success(let succeed):
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

    try requester.request(content: CustomUpdateContentObjects.mediaContentValid()) { result in
      switch result {
      case .failure(let error):
        return XCTFail(
          "Expecting the request to succeed instead receieved: \(error)"
        )
      case .success(let succeed):
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
    try requester.request(content: CustomUpdateContentObjects.imageContentValid()) { _ in
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
    XCTAssertEqual(
      factory.capturedParameters as? [String: String],
      validImageContentParameterDictionary,
      "Request should have the correct parameters"
    )
  }

  func testHandlingRequestInvalidImageContentError() throws {
    try requester.request(content: CustomUpdateContentObjects.imageContentValid()) { result in
      switch result {
      case .failure(let error):
        guard case .contentParsing = error else {
          return XCTFail("Should not be a decoding error")
        }
      case .success:
        XCTFail("Should not succeed")
      }
    }
  }

  func testHandlingRequestErrorWithImageContent() throws {
    var completionWasInvoked = false
    try requester.request(content: CustomUpdateContentObjects.imageContentValid()) { result in
      switch result {
      case .failure(let error):
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
    try requester.request(content: CustomUpdateContentObjects.imageContentValid()) { result in
      switch result {
      case .failure(let error):
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

    try requester.request(content: CustomUpdateContentObjects.imageContentValid()) { result in
      switch result {
      case .failure(let error):
        return XCTFail(
          "Expecting the request to succeed instead receieved: \(error)"
        )
      case .success(let succeed):
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

    try requester.request(content: CustomUpdateContentObjects.imageContentValid()) { result in
      switch result {
      case .failure(let error):
        return XCTFail(
          "Expecting the request to succeed instead receieved: \(error)"
        )
      case .success(let succeed):
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
