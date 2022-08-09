/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import XCTest

final class LoginResponseURLParserTests: XCTestCase {
  func testInitWithAllParameters() throws {
    let sampleURL = SampleURLs.LoginResponses.withDefaultParameters
    let userSession = try XCTUnwrap(
      LoginResponseURLParser().parseURL(url: sampleURL),
      "Should return user session instance with all valid parameters"
    )
    let accessToken = try XCTUnwrap(
      userSession.accessToken,
      "User session should have an access token instance"
    )

    XCTAssertEqual(
      accessToken.tokenString,
      RawLoginParameters.accessToken,
      "Should set access token from incoming URL"
    )
    XCTAssertEqual(
      accessToken.dataAccessExpirationDate,
      RawLoginParameters.dataAccessExpirationDate,
      "Should set token data expiration date from incoming URL"
    )
    XCTAssertEqual(
      accessToken.expirationDate,
      RawLoginParameters.expiresDate,
      "Should set token expiration date from incoming URL"
    )
    XCTAssertEqual(
      userSession.userID,
      RawLoginParameters.userID,
      "User ID should be derived from the signed request"
    )
    XCTAssertEqual(
      userSession.graphDomain,
      GraphDomain.faceBook,
      "Should set graph domain from incoming URL"
    )
    XCTAssertEqual(
      userSession.requestedPermissions,
      RawLoginParameters.requestedPermissions,
      "Should set requested permissions from granted scopes in incoming URL"
    )
    XCTAssertEqual(
      userSession.declinedPermissions,
      RawLoginParameters.declinedPermissions,
      "Should set declined permissions from denied scopes in incoming URL"
    )
  }

  func testInitWithNoParameters() throws {
    XCTAssertNil(
      LoginResponseURLParser().parseURL(url: SampleURLs.loginRedirect),
      "Should return nil if incoming URL has no parameters"
    )
  }

  func testInitWithNoExpirationDatesParameters() throws {
    let sampleURL = SampleURLs.LoginResponses.withNoExpirationParameters
    let userSession = try XCTUnwrap(
      LoginResponseURLParser().parseURL(url: sampleURL),
      "Should return user session instance with no expiration time parameters"
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

  func testInitWithNoExpiresParameter() throws {
    let sampleURL = SampleURLs.LoginResponses.withNoExpiresParameter
    let userSession = try XCTUnwrap(
      LoginResponseURLParser().parseURL(url: sampleURL),
      "Should return user session instance with no expires parameter"
    )
    let accessToken = try XCTUnwrap(
      userSession.accessToken,
      "User session should have an access token instance"
    )

    XCTAssertEqual(
      accessToken.expirationDate.timeIntervalSince1970,
      RawLoginParameters.expiresAtDate.timeIntervalSince1970,
      accuracy: 0.005,
      "Should use expires_at parameter if the expires parameter is not returned"
    )
  }

  func testInitWithOnlyExpiresInParameter() throws {
    let sampleURL = SampleURLs.LoginResponses.withNoExpiresAndExpiresAtParameters
    let userSession = try XCTUnwrap(
      LoginResponseURLParser().parseURL(url: sampleURL),
      "Should return user session instance with no expires_in parameter"
    )
    let accessToken = try XCTUnwrap(
      userSession.accessToken,
      "User session should have an access token instance"
    )
    print(RawLoginParameters.expiresInDate)

    XCTAssertEqual(
      accessToken.expirationDate.timeIntervalSince1970,
      RawLoginParameters.expiresInDate.timeIntervalSince1970,
      accuracy: 0.005,
      "Should use expires_in parameter if the expires parameter is not returned"
    )
  }

  func testInitWithNoDeclinedPermissions() throws {
    let sampleURL = SampleURLs.LoginResponses.withEmptyPermissions
    let userSession = try XCTUnwrap(
      LoginResponseURLParser().parseURL(url: sampleURL),
      "Should be able to create a user session from parameters that lack denied permissions"
    )

    XCTAssertEqual(
      userSession.declinedPermissions,
      [],
      "Empty array should be derived from no permissions"
    )
  }

  func testInitWithNoAccessToken() throws {
    let sampleURL = SampleURLs.LoginResponses.withNoAccessToken
    XCTAssertNil(
      LoginResponseURLParser().parseURL(url: sampleURL),
      "Should return nil if the access token parameter does not exist"
    )
  }

  func testInitWithNoUserID() throws {
    let sampleURL = SampleURLs.LoginResponses.withNoSignedRequestParameter
    XCTAssertNil(
      LoginResponseURLParser().parseURL(url: sampleURL),
      "Should return null if the signed request is not provided"
    )
  }

  func testInitWithInvalidUserID() throws {
    let sampleURL = SampleURLs.LoginResponses.withInvalidSignedRequestParameter
    XCTAssertNil(
      LoginResponseURLParser().parseURL(url: sampleURL),
      "Should return null with invalid signed request"
    )
  }
}
