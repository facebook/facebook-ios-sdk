/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

extension BridgeAPITests {

  // MARK: - Setting Session Completion Handler

  func testInvokingAuthSessionCompletionHandlerFromHandlerWithValidURLWithoutError() {
    var capturedSuccesses = [Bool]()
    var capturedErrors = [Error?]()
    let handler: SuccessBlock = { success, error in
      capturedSuccesses.append(success)
      capturedErrors.append(error)
    }
    api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy()
    api.authenticationSessionState = .started
    api.setSessionCompletionHandlerFromHandler(handler)

    api.authenticationSessionCompletionHandler?(sampleURL, nil)

    XCTAssertEqual(
      capturedSuccesses,
      [true, false],
      "Should complete each callback with the expected status"
    )
    XCTAssertNil(
      capturedErrors[0], // using array literal here since `first` would return an `Error??` instead of an `Error?`
      "Should complete the first callback without an error"
    )
    XCTAssertEqual(
      capturedErrors.last as? NSError,
      makeLoginCancellationError(url: sampleURL) as NSError?,
      "Should complete with the expected error"
    )

    verifyAuthenticationPropertiesReset()
  }

  func testInvokingAuthSessionCompletionHandlerFromHandlerWithInvalidURLWithoutError() {
    let url = URL(string: " ")

    var capturedSuccesses = [Bool]()
    var capturedErrors = [Error?]()
    let handler: SuccessBlock = { success, error in
      capturedSuccesses.append(success)
      capturedErrors.append(error)
    }
    api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy()
    api.authenticationSessionState = .started
    api.setSessionCompletionHandlerFromHandler(handler)

    api.authenticationSessionCompletionHandler?(url, nil)

    XCTAssertEqual(
      capturedSuccesses.count,
      1,
      "Should only invoke the completion once"
    )
    XCTAssertFalse(
      capturedSuccesses[0],
      "Completing with an invalid url should invoke the handler with a failure"
    )
    XCTAssertNil(
      capturedErrors[0],
      "Completing with an invalid url should not invoke the handler with an error"
    )
    verifyAuthenticationPropertiesReset()
  }

  func testInvokingAuthSessionCompletionHandlerFromHandlerWithoutURLWithoutError() {
    var capturedSuccesses = [Bool]()
    var capturedErrors = [Error?]()
    let handler: SuccessBlock = { success, error in
      capturedSuccesses.append(success)
      capturedErrors.append(error)
    }
    api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy()
    api.authenticationSessionState = .started

    api.setSessionCompletionHandlerFromHandler(handler)
    api.authenticationSessionCompletionHandler?(nil, nil)

    XCTAssertEqual(
      capturedSuccesses.count,
      1,
      "Should only invoke the completion once"
    )
    XCTAssertFalse(
      capturedSuccesses[0],
      "Completing with a missing url should invoke the handler with a failure"
    )
    XCTAssertNil(
      capturedErrors[0],
      "Completing with a missing url should not invoke the handler with an error"
    )
    verifyAuthenticationPropertiesReset()
  }

  func testInvokingAuthSessionCompletionHandlerFromHandlerWithValidURLWithError() {
    var capturedSuccesses = [Bool]()
    var capturedErrors = [Error?]()
    let handler: SuccessBlock = { success, error in
      capturedSuccesses.append(success)
      capturedErrors.append(error)
    }
    api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy()
    api.authenticationSessionState = .started
    api.setSessionCompletionHandlerFromHandler(handler)

    api.authenticationSessionCompletionHandler?(sampleURL, SampleError())

    XCTAssertEqual(
      capturedSuccesses.count,
      1,
      "Should only invoke the completion once"
    )
    XCTAssertFalse(
      capturedSuccesses[0],
      "Completing with an error and a URL should invoke the handler with a failure"
    )
    XCTAssertTrue(
      capturedErrors[0] is SampleError,
      "Completing with an error and a URL should invoke the handler with that same error"
    )
    verifyAuthenticationPropertiesReset()
  }

  func testInvokingAuthSessionCompletionHandlerFromHandlerWithInvalidURLWithError() {
    let url = URL(string: " ")

    var capturedSuccesses = [Bool]()
    var capturedErrors = [Error?]()
    let handler: SuccessBlock = { success, error in
      capturedSuccesses.append(success)
      capturedErrors.append(error)
    }
    api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy()
    api.authenticationSessionState = .started
    api.setSessionCompletionHandlerFromHandler(handler)

    api.authenticationSessionCompletionHandler?(url, SampleError())

    XCTAssertEqual(
      capturedSuccesses.count,
      1,
      "Should only invoke the completion once"
    )
    XCTAssertFalse(
      capturedSuccesses[0],
      "Completing with an error and an invalid URL should invoke the handler with a failure"
    )
    XCTAssertTrue(
      capturedErrors[0] is SampleError,
      "Completing with an error and an invalid URL should invoke the handler with that same error"
    )
    verifyAuthenticationPropertiesReset()
  }

  func testInvokingAuthSessionCompletionHandlerFromHandlerWithoutURLWithError() {
    var capturedSuccesses = [Bool]()
    var capturedErrors = [Error?]()
    let handler: SuccessBlock = { success, error in
      capturedSuccesses.append(success)
      capturedErrors.append(error)
    }
    api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy()
    api.authenticationSessionState = .started
    api.setSessionCompletionHandlerFromHandler(handler)

    api.authenticationSessionCompletionHandler?(nil, SampleError())

    XCTAssertEqual(
      capturedSuccesses.count,
      1,
      "Should only invoke the completion once"
    )
    XCTAssertFalse(
      capturedSuccesses[0],
      "Completing with an error and a missing URL should invoke the handler with a failure"
    )
    XCTAssertTrue(
      capturedErrors[0] is SampleError,
      "Completing with an error and a missing URL should invoke the handler with that same error"
    )
    verifyAuthenticationPropertiesReset()
  }

  // MARK: - Helpers

  func makeLoginCancellationError(url: URL) -> Error {
    let errorMessage = "Login attempt cancelled by alternate call to openURL from: \(url)"
    return errorFactory.error(
      code: CoreError.errorBridgeAPIInterruption.rawValue,
      userInfo: [ErrorLocalizedDescriptionKey: errorMessage],
      message: errorMessage,
      underlyingError: nil
    )
  }

  func verifyAuthenticationPropertiesReset() {
    XCTAssertNil(api.authenticationSession)
    XCTAssertNil(api.authenticationSessionCompletionHandler)
    XCTAssertEqual(api.authenticationSessionState, .none)
  }
}
