/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import XCTest

extension LoginError: Equatable {
  public static func == (lhs: LoginError, rhs: LoginError) -> Bool {
    return lhs.localizedDescription == rhs.localizedDescription
  }
}

final class LoginResponseURLParserTests: XCTestCase {
  func testParseWithAllParameters() throws {
    let sampleURL = SampleURLs.LoginResponses.withDefaultParameters
    let userSession = try LoginResponseURLParser().parse(url: sampleURL)
    let accessToken = try XCTUnwrap(
      userSession.accessToken,
      "User session should have an access token instance"
    )

    XCTAssertEqual(
      accessToken.tokenString,
      SampleRawLoginResponse.accessToken,
      "Should set access token from incoming URL"
    )
    XCTAssertEqual(
      accessToken.dataAccessExpirationDate,
      SampleRawLoginResponse.dataAccessExpirationDate,
      "Should set token data expiration date from incoming URL"
    )
    XCTAssertEqual(
      accessToken.expirationDate,
      SampleRawLoginResponse.expiresDate,
      "Should set token expiration date from incoming URL"
    )
    XCTAssertEqual(
      userSession.userID,
      SampleRawLoginResponse.userID,
      "User ID should be derived from the signed request"
    )
    XCTAssertEqual(
      userSession.graphDomain,
      GraphDomain.facebook,
      "Should set graph domain from incoming URL"
    )
    XCTAssertEqual(
      userSession.requestedPermissions,
      SampleRawLoginResponse.requestedPermissions,
      "Should set requested permissions from granted scopes in incoming URL"
    )
    XCTAssertEqual(
      userSession.declinedPermissions,
      SampleRawLoginResponse.declinedPermissions,
      "Should set declined permissions from denied scopes in incoming URL"
    )
  }

  func testInitWithAllQueryItems() throws {
    let sampleURL = SampleURLs.LoginResponses.withDefaultParametersWithQuery
    let userSession = try XCTUnwrap(
      LoginResponseURLParser().parse(url: sampleURL),
      "Should return user session instance with all valid default parameters as query items"
    )
    let accessToken = try XCTUnwrap(
      userSession.accessToken,
      "User session should have an access token instance"
    )

    XCTAssertEqual(
      accessToken.tokenString,
      SampleRawLoginResponse.accessToken,
      "Should set access token from incoming URL"
    )
    XCTAssertEqual(
      accessToken.dataAccessExpirationDate,
      SampleRawLoginResponse.dataAccessExpirationDate,
      "Should set token data expiration date from incoming URL"
    )
    XCTAssertEqual(
      accessToken.expirationDate,
      SampleRawLoginResponse.expiresDate,
      "Should set token expiration date from incoming URL"
    )
    XCTAssertEqual(
      userSession.userID,
      SampleRawLoginResponse.userID,
      "User ID should be derived from the signed request"
    )
    XCTAssertEqual(
      userSession.graphDomain,
      GraphDomain.facebook,
      "Should set graph domain from incoming URL"
    )
    XCTAssertEqual(
      userSession.requestedPermissions,
      SampleRawLoginResponse.requestedPermissions,
      "Should set requested permissions from granted scopes in incoming URL"
    )
    XCTAssertEqual(
      userSession.declinedPermissions,
      SampleRawLoginResponse.declinedPermissions,
      "Should set declined permissions from denied scopes in incoming URL"
    )
  }

  func testInitWithNoParameters() throws {
    let sampleURL = SampleURLs.loginRedirect
    XCTAssertThrowsError(
      _ = try LoginResponseURLParser().parse(url: sampleURL)
    ) { error in
      XCTAssertEqual(error as? LoginError, .invalidIncomingURL, "Should return error for a URL with no parameters")
    }
  }

  func testParseWithNoExpirationDatesParameters() throws {
    let sampleURL = SampleURLs.LoginResponses.withNoExpirationParameters
    let userSession = try XCTUnwrap(
      LoginResponseURLParser().parse(url: sampleURL),
      "Should return user session instance with no expiration parameters"
    )
    let accessToken = try XCTUnwrap(
      userSession.accessToken,
      "User session should have an access token instance"
    )

    XCTAssertEqual(
      accessToken.dataAccessExpirationDate,
      Date.distantFuture,
      "Data access expiration date should be set to distant future if no expiration parameters exist"
    )
    XCTAssertEqual(
      accessToken.expirationDate,
      Date.distantFuture,
      "Expiration date should be set to distant future if no expiration parameters exist"
    )
  }

  func testParseWithNoExpiresParameter() throws {
    let sampleURL = SampleURLs.LoginResponses.withNoExpiresParameter
    let userSession = try XCTUnwrap(
      LoginResponseURLParser().parse(url: sampleURL),
      "Should return user session instance with no expires parameters"
    )
    let accessToken = try XCTUnwrap(
      userSession.accessToken,
      "User session should have an access token instance"
    )

    XCTAssertEqual(
      accessToken.expirationDate.timeIntervalSince1970,
      SampleRawLoginResponse.expiresAtDate.timeIntervalSince1970,
      accuracy: 0.005,
      "Should use expires_at parameter if the expires parameter is not returned"
    )
  }

  func testParseWithOnlyExpiresInParameter() throws {
    let sampleURL = SampleURLs.LoginResponses.withNoExpiresAndExpiresAtParameters
    let userSession = try XCTUnwrap(
      LoginResponseURLParser().parse(url: sampleURL),
      "Should return user session instance with no expires and no expires_at parameters"
    )
    let accessToken = try XCTUnwrap(
      userSession.accessToken,
      "User session should have an access token instance"
    )

    XCTAssertEqual(
      accessToken.expirationDate.timeIntervalSince1970,
      SampleRawLoginResponse.expiresInDate.timeIntervalSince1970,
      accuracy: 0.005,
      "Should use expires_in parameter if the expires parameter is not returned"
    )
  }

  func testParseWithNoDeclinedPermissions() throws {
    let sampleURL = SampleURLs.LoginResponses.withEmptyPermissions
    let userSession = try XCTUnwrap(
      LoginResponseURLParser().parse(url: sampleURL),
      "Should return user session instance with no declined permissions parameters"
    )

    XCTAssertEqual(
      userSession.declinedPermissions,
      [],
      "Empty array should be derived from no permissions"
    )
  }

  func testParseWithNoAccessTokenAndError() throws {
    let sampleURL = SampleURLs.LoginResponses.withNoAccessTokenAndError
    XCTAssertThrowsError(
      _ = try LoginResponseURLParser().parse(url: sampleURL)
    ) { error in
      XCTAssertEqual(
        error as? LoginError,
        .cancelledLogin,
        "Should return cancellationLogin if the access token parameter does not exist and no error in Url"
      )
    }
  }

  func testParseWithNoUserID() throws {
    let sampleURL = SampleURLs.LoginResponses.withNoSignedRequestParameter
    XCTAssertThrowsError(
      _ = try LoginResponseURLParser().parse(url: sampleURL)
    ) { error in
      XCTAssertEqual(
        error as? LoginError,
        .invalidIncomingURL,
        "Should return error if signed request is not provided"
      )
    }
  }

  func testParseWithInvalidUserID() throws {
    let sampleURL = SampleURLs.LoginResponses.withInvalidSignedRequestParameter
    XCTAssertThrowsError(
      _ = try LoginResponseURLParser().parse(url: sampleURL)
    ) { error in
      XCTAssertEqual(
        error as? LoginError,
        .unhandledError(message: "InvalidSignedRequest with InvalidSignedRequest"),
        "Should return error if signed request is invalid"
      )
    }
  }

  func testParseWithCancelledUrl() throws {
    let sampleURL = SampleURLs.LoginResponses.withCancellationRequest
    XCTAssertThrowsError(
      _ = try LoginResponseURLParser().parse(url: sampleURL)
    ) { error in
      XCTAssertEqual(
        error as? LoginError,
        .cancelledLogin,
        "Should return cancelledLogin error if received error is nil and user session data is not provided"
      )
    }
  }

  func testIsCancellationWithCancelledURL() throws {
    let sampleURL = SampleURLs.loginRedirect
    XCTAssertTrue(
      LoginResponseURLParser().isValidAuthenticationURL(sampleURL),
      "URL shows cancelled session if incoming URL has no parameters"
    )
  }

  func testIsValidAuthenticationURLWithValidURL() throws {
    let sampleURL = SampleURLs.LoginResponses.withDefaultParameters
    let isValid = LoginResponseURLParser().isValidAuthenticationURL(sampleURL)

    XCTAssertTrue(isValid, "Should return true when URL begins with the Meta login redirect uri")
  }

  func testIsValidAuthenticationURLWithValidHostAndInvalidScheme() throws {
    let sampleURL = URL(string: "fbconnect://failure")!
    let isValid = LoginResponseURLParser().isValidAuthenticationURL(sampleURL)

    XCTAssertFalse(isValid, "Should return false when URL does not begin with the Meta login redirect uri")
  }

  func testIsValidAuthenticationURLWithInvalidURLAndValidScheme() throws {
    let sampleURL = URL(string: "example://success")!
    let isValid = LoginResponseURLParser().isValidAuthenticationURL(sampleURL)

    XCTAssertFalse(isValid, "Should return false when URL does not begin with the Meta login redirect uri")
  }

  func testIsValidAuthenticationURLWithInvalidHostAndInvalidScheme() throws {
    let isValid = LoginResponseURLParser().isValidAuthenticationURL(SampleURLs.example)

    XCTAssertFalse(isValid, "Should return false when URL does not begin with the Meta login redirect uri")
  }
}
