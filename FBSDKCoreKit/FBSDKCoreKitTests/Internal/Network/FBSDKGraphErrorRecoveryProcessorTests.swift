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

private class TestGraphErrorRecoveryProcessorDelegate: NSObject, GraphErrorRecoveryProcessorDelegate {

  var wasRecoveryAttempted = false
  var capturedProcessor: GraphErrorRecoveryProcessor?
  var capturedDidRecover = false
  var capturedError: NSError?

  func processorDidAttemptRecovery(
    _ processor: GraphErrorRecoveryProcessor,
    didRecover: Bool,
    error: Error?
  ) {
    wasRecoveryAttempted = true
    capturedProcessor = processor
    capturedDidRecover = didRecover
    capturedError = error as NSError?
  }
}

private class TestErrorRecoveryAttempter: ErrorRecoveryAttempter {

  var capturedError: Error?
  var capturedOptionIndex: UInt?
  var capturedCompletion: ((Bool) -> Void)?

  override func attemptRecovery(
    fromError error: Error,
    optionIndex recoveryOptionIndex: UInt,
    completionHandler: @escaping (Bool) -> Void
  ) {
    capturedError = error
    capturedOptionIndex = recoveryOptionIndex
    capturedCompletion = completionHandler
  }
}

class FBSDKGraphErrorRecoveryProcessorTests: XCTestCase {

  private enum Keys {
    static let errorKey = "com.facebook.sdk:FBSDKGraphRequestErrorKey"
  }

  private enum SampleErrors {

    static let recoverableCode = Int(GraphRequestError.recoverable.rawValue)
    static let transientCode = Int(GraphRequestError.transient.rawValue)
    static let transient = NSError(
      domain: "test",
      code: transientCode,
      userInfo: [Keys.errorKey: transientCode]
    )

    static func createRecoverable(attempter: ErrorRecoveryAttempter) -> NSError {
      NSError(
        domain: "test",
        code: recoverableCode,
        userInfo: [
          Keys.errorKey: recoverableCode,
          NSRecoveryAttempterErrorKey: attempter
        ]
      )
    }
  }

  let processor = GraphErrorRecoveryProcessor(accessTokenString: "Foo")
  private let delegate = TestGraphErrorRecoveryProcessorDelegate()
  private let attempter = TestErrorRecoveryAttempter()

  func testProcessingRandomErrorCategories() {
    (1..<100).forEach { _ in
      let error = NSError(domain: "test", code: 0, userInfo: [Keys.errorKey: Fuzzer.random])
      processor.processError(error, request: TestGraphRequest(), delegate: delegate)
    }
  }

  func testProcessingTransientError() {
    XCTAssertTrue(
      processor.processError(SampleErrors.transient, request: TestGraphRequest(), delegate: delegate),
      "Should successfully process a transient graph request error"
    )
    XCTAssertEqual(
      delegate.capturedProcessor,
      processor,
      "Should invoke the delegate with the expected recovery processor"
    )
    XCTAssertTrue(
      delegate.capturedDidRecover,
      "Should inform the delegate about the successful recovery"
    )
    XCTAssertNil(
      delegate.capturedError
    )
  }

  func testProcessingRecoverableErrorWithIdenticalAccessTokenString() throws {
    let processor = GraphErrorRecoveryProcessor(accessTokenString: name)
    let error = SampleErrors.createRecoverable(attempter: attempter)

    XCTAssertTrue(
      processor.processError(
        error,
        request: createGraphRequest(tokenString: name),
        delegate: delegate
      ),
      "Should successfully process a recoverable graph request error"
    )

    let completion = try XCTUnwrap(attempter.capturedCompletion)
    let wasRecoverySuccessful = Bool.random()
    completion(wasRecoverySuccessful)

    XCTAssertEqual(
      delegate.capturedProcessor,
      processor,
      "Should invoke the delegate with the expected recovery processor"
    )
    XCTAssertEqual(
      delegate.capturedDidRecover,
      wasRecoverySuccessful,
      "Should inform the delegate about the status of the recovery"
    )
    XCTAssertTrue(
      delegate.capturedError === error,
      "Should invoke the delegate with the expected error"
    )
  }

  func testProcessingRecoverableErrorWithDifferentAccessTokenStrings() throws {
    XCTAssertFalse(
      processor.processError(
        SampleErrors.createRecoverable(attempter: attempter),
        request: createGraphRequest(tokenString: name),
        delegate: delegate
      ),
      "Should not attempt to recover a graph request error if the access token strings do not match"
    )
    XCTAssertFalse(
      delegate.wasRecoveryAttempted,
      "Should not invoke the delegate when recovery is not attempted"
    )
  }

  // MARK: - Helpers

  func createGraphRequest(tokenString: String) -> GraphRequestProtocol {
    TestGraphRequest(
      graphPath: "me",
      parameters: [:],
      tokenString: tokenString
    )
  }
}
