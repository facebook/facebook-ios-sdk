/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin

import AuthenticationServices
import XCTest

final class AppleWebAuthenticatorTests: XCTestCase {
  // swiftlint:disable implicitly_unwrapped_optional
  var authenticator: AppleWebAuthenticator!
  var sessionFactory: TestASWebAuthenticationSessionFactory!
  var presentationContextProvider: TestASWebAuthenticationPresentationContextProvider!
  // swiftlint:enable implicitly_unwrapped_optional

  var session: TestASWebAuthenticationSession? {
    sessionFactory.createdSession as? TestASWebAuthenticationSession
  }

  override func setUp() async throws {
    try await super.setUp()

    sessionFactory = TestASWebAuthenticationSessionFactory()
    presentationContextProvider = TestASWebAuthenticationPresentationContextProvider()
    await makeAuthenticator()
  }

  private func makeAuthenticator(shouldSessionStartSucceed: Bool = true) async {
    sessionFactory.shouldSessionStartSucceed = shouldSessionStartSucceed
    authenticator = AppleWebAuthenticator()

    await authenticator.setDependencies(
      .init(
        sessionFactory: sessionFactory,
        presentationContextProvider: presentationContextProvider
      )
    )
  }

  override func tearDown() {
    sessionFactory = nil
    presentationContextProvider = nil
    authenticator = nil

    super.tearDown()
  }

  // MARK: - Dependencies

  func testDefaultDependencies() async throws {
    authenticator = AppleWebAuthenticator()
    let dependencies = try await authenticator.getDependencies()

    XCTAssertTrue(
      dependencies.sessionFactory is DefaultASWebAuthenticationSessionFactory,
      .defaultSessionFactory
    )
    XCTAssertTrue(
      dependencies.presentationContextProvider is DefaultASWebAuthenticationSessionPresentationContextProvider,
      .defaultPresentationContextProvider
    )
  }

  func testCustomDependencies() async throws {
    let dependencies = try await authenticator.getDependencies()

    XCTAssertIdentical(
      dependencies.sessionFactory as AnyObject,
      sessionFactory,
      .customSessionFactory
    )
    XCTAssertIdentical(
      dependencies.presentationContextProvider as AnyObject,
      presentationContextProvider,
      .customPresentationContextProvider
    )
  }

  // MARK: - Authentication

  func testInProgressAuthentication() async throws {
    Task {
      _ = try await authenticator.authenticate(to: .sample)
    }

    try await Task.sleep(nanoseconds: 10_000)

    do {
      _ = try await authenticator.authenticate(to: .sample)
      XCTFail(.concurrentAuthenticationFails)
    } catch LoginFailure.inProgress {
      // Expecting this error
    } catch {
      XCTFail(.concurrentAuthenticationFails)
    }
  }

  func testSubsequentRepeatAuthentication() async throws {
    Task {
      try await Task.sleep(nanoseconds: 10_000)
      session?.completionHandler?(.authenticated, nil)
    }

    _ = try await authenticator.authenticate(to: .sample)

    Task {
      try await Task.sleep(nanoseconds: 10_000)
      session?.completionHandler?(.authenticated, nil)
    }

    do {
      _ = try await authenticator.authenticate(to: .sample)
    } catch {
      XCTFail(.subsequentAuthenticationProceeds)
    }
  }

  func testSessionCreated() async throws {
    Task {
      _ = try await authenticator.authenticate(to: .sample)
    }

    try await Task.sleep(nanoseconds: 10_000)

    let session = try XCTUnwrap(session, .createsSession)
    XCTAssertEqual(session.url, .sample, .createsSession)
    XCTAssertNil(session.callbackURLScheme, .createsSession)
    XCTAssertIdentical(
      session.presentationContextProvider as AnyObject,
      presentationContextProvider as AnyObject,
      .presentationContextProvider
    )
  }

  func testSessionStarted() async throws {
    Task {
      _ = try await authenticator.authenticate(to: .sample)
    }

    try await Task.sleep(nanoseconds: 10_000)

    let session = try XCTUnwrap(session, .createsSession)
    XCTAssertTrue(session.wasStartCalled, .sessionStarted)
  }

  func testSessionStartFailure() async {
    await makeAuthenticator(shouldSessionStartSucceed: false)

    do {
      _ = try await authenticator.authenticate(to: .sample)
      XCTFail(.sessionStartFailure)
    } catch LoginFailure.sessionStart {
      // Expecting this error
    } catch {
      XCTFail(.sessionStartFailure)
    }
  }

  func testMissingResultsFailure() async throws {
    sessionFactory.autocompleteArguments = (nil, nil)

    do {
      _ = try await authenticator.authenticate(to: .sample)
    } catch LoginFailure.unknown {
      // Expecting this error
    } catch {
      XCTFail(.missingResultsFailure)
    }
  }

  func testUnrecognizedErrorFailure() async throws {
    struct TestError: Error, Equatable {}
    let testError = TestError()
    sessionFactory.autocompleteArguments = (nil, testError)

    do {
      _ = try await authenticator.authenticate(to: .sample)
    } catch LoginFailure.unknown {
      // Expecting this error
    } catch {
      XCTFail(.unrecognizedErrorFailure)
    }
  }

  func testCancelationFailure() async {
    sessionFactory.autocompleteArguments = (nil, ASWebAuthenticationSessionError(.canceledLogin))

    do {
      _ = try await authenticator.authenticate(to: .sample)
    } catch LoginFailure.isCanceled {
      // Expecting this error
    } catch {
      XCTFail(.cancelationFailure)
    }
  }

  func testMissingPresentationContextFailure() async {
    let testError = ASWebAuthenticationSessionError(.presentationContextNotProvided)
    sessionFactory.autocompleteArguments = (nil, testError)

    do {
      _ = try await authenticator.authenticate(to: .sample)
    } catch let LoginFailure.internal(error) {
      XCTAssertEqual(error as? ASWebAuthenticationSessionError, testError, .invalidPresentationContext)
    } catch {
      XCTFail(.invalidPresentationContext)
    }
  }

  func testInvalidPresentationContextFailure() async {
    let testError = ASWebAuthenticationSessionError(.presentationContextInvalid)
    sessionFactory.autocompleteArguments = (nil, testError)

    do {
      _ = try await authenticator.authenticate(to: .sample)
    } catch let LoginFailure.internal(error) {
      XCTAssertEqual(error as? ASWebAuthenticationSessionError, testError, .invalidPresentationContext)
    } catch {
      XCTFail(.invalidPresentationContext)
    }
  }

  func testSuccessfulAuthentication() async throws {
    sessionFactory.autocompleteArguments = (.authenticated, nil)
    let url = try await authenticator.authenticate(to: .sample)
    XCTAssertEqual(url, .authenticated, .success)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let defaultSessionFactory = "An Apple web authenticator uses a default session factory by default"
  static let defaultPresentationContextProvider = """
    An Apple web authenticator uses a default session presentation context provider by default
    """

  static let customSessionFactory = "An Apple web authenticator uses a custom session factory when provided"
  static let customPresentationContextProvider = """
    An Apple web authenticator uses a custom session presentation context provider when provided
    """

  static let concurrentAuthenticationFails = """
    Attempting to authenticate fails while another authentication attempt is in progress
    """
  static let subsequentAuthenticationProceeds = """
    Attempting to authenticate succeeds after a completed authentication attempt
    """

  static let createsSession = """
    When authenticating, an authenticator uses its session factory to create a session with the provided
    authentication URL and without a callback URL scheme.
    """
  static let presentationContextProvider = "The session is configured with the presentation context provider dependency"

  static let sessionStarted = "Authenticating starts the session"
  static let sessionStartFailure = "A failed session start throws an error"
  static let missingResultsFailure = "A session completion called with neither a URL nor an error fails"
  static let unrecognizedErrorFailure = "A session completion called with an unrecognized error fails"
  static let cancelationFailure = "A session completion called with a cancelation error fails"
  static let invalidPresentationContext = "A session completion called with a presentation context error fails"

  static let success = "A successful authentication returns a URL"
}

// MARK: - Test Values

fileprivate extension URL {
  // swiftlint:disable force_unwrapping
  static let sample = URL(string: "https://facebook.com/authenticate-me")!
  static let authenticated = URL(string: "https://facebook.com/did-authenticate")!
  // swiftlint:enable force_unwrapping
}
