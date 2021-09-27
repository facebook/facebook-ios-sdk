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

@testable import FacebookGamingServices

#if FBSDK_SWIFT_PACKAGE
import FacebookCore
#else
import FBSDKCoreKit
#endif

import TestTools
import XCTest

class TournamentUpdaterTest: XCTestCase {
  let factory = TestGraphRequestFactory()
  let score = 10
  lazy var updater = TournamentUpdater(graphRequestFactory: factory)
  lazy var tournament = Tournament(identifier: "12345", expiration: Date(), title: "test", payload: nil)

  func testDependencies() {
    XCTAssertTrue(
      TournamentUpdater().graphRequestFactory is GraphRequestFactory,
      "Should have a default GraphRequestFactory of the expected type"
    )
  }

  func testCustomDependencies() {
    XCTAssertEqual(
      updater.graphRequestFactory as? TestGraphRequestFactory,
      factory,
      "Should be able to create with a custom graph request factory"
    )
  }

  func testUpdate() throws {
    updater.update(tournament: tournament, score: score) { _ in
      XCTFail("Should not reach here")
    }

    let request = try XCTUnwrap(factory.capturedRequests.first)

    XCTAssertEqual(
      request.startCallCount,
      1,
      "Should start the request to update tournaments"
    )
    XCTAssertEqual(
      factory.capturedGraphPath,
      "\(tournament.identifier)/update_score",
      "Should create a request with the expected graph path"
    )
    XCTAssertEqual(
      factory.capturedParameters as? [String: Int],
      ["score": score],
      "Should create a request with the expected parameters"
    )
  }

  func testHandlingUpdateError() throws {
    var completionWasInvoked = false
    updater.update(tournament: tournament, score: score) { result in
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

  func testHandlingUpdateInvalidResult() throws {
    var completionWasInvoked = false
    updater.update(tournament: tournament, score: score) { result in
      switch result {
      case .failure(let error):
        guard case .decoding = error else {
          return XCTFail("Should fail with decoding error but instead failed with: \(error)")
        }
      case .success:
        XCTFail("Should not succeed")
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, TournamentUpdateGraphAPIResults.invalid, nil)

    XCTAssert(completionWasInvoked)
  }

  func testHandlingUpdateSuccessFalse() throws {
    var completionWasInvoked = false
    updater.update(tournament: tournament, score: score) { result in
      switch result {
      case .failure(let error):
        guard case .decoding = error else {
          return XCTFail("Should fail with decoding error but instead failed with: \(error)")
        }
      case .success():
        XCTFail("Should not succeed")
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, TournamentUpdateGraphAPIResults.successFalse, nil)

    XCTAssert(completionWasInvoked)
  }

  func testHandlingUpdateSuccess() throws {
    var completionWasInvoked = false
    var didSucceed = false
    updater.update(tournament: tournament, score: score) { result in
      switch result {
      case .failure(let error):
        return XCTFail(
          "Expecting the request to succeed instead received: \(error)"
        )
      case .success():
        didSucceed = true
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, TournamentUpdateGraphAPIResults.successTrue, nil)

    XCTAssert(completionWasInvoked)
    XCTAssertTrue(didSucceed)
  }

  enum TournamentUpdateGraphAPIResults {
    static let successTrue = ["success": 1]
    static let successFalse = ["success": 0]
    static let invalid = ["not_success": "value"]
  }
}
