/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import TestTools
import XCTest

final class AuthenticationTokenFactoryTests: XCTestCase {

  let certificate = "-----BEGIN CERTIFICATE-----\nMIIDgjCCAmoCCQDMso+U6N9AMjANBgkqhkiG9w0BAQsFADCBgjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAldBMRAwDgYDVQQHDAdTZWF0dGxlMREwDwYDVQQKDAhGYWNlYm9vazEMMAoGA1UECwwDRW5nMRIwEAYDVQQDDAlwYW5zeTA0MTkxHzAdBgkqhkiG9w0BCQEWEHBhbnN5MDQxOUBmYi5jb20wHhcNMjAxMTAzMDAzNTI1WhcNMzAxMTAxMDAzNTI1WjCBgjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAldBMRAwDgYDVQQHDAdTZWF0dGxlMREwDwYDVQQKDAhGYWNlYm9vazEMMAoGA1UECwwDRW5nMRIwEAYDVQQDDAlwYW5zeTA0MTkxHzAdBgkqhkiG9w0BCQEWEHBhbnN5MDQxOUBmYi5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD0R8/zzuJ5SM+8KBgshg+sKARfm4Ad7Qv7Vi0L8xoXpReXxefDHF7jI9o6pLsp5OIEmnhRjTlbdT7APK1pZ8dHjOdod6xWSoQigUplYOqa5iuVx7IqD15PUhx6/LqcAtHFKDtKOPuIc8CqkmVUyGRMq2OxdCoiWix5z79pSDILmlRWsn4UOCpFU/Ix75YL/JD19IHgwgh4XCxDwUVhmpgG+jI5l9a3ZCBx7JwZAoJ/Z/OpVbguAlBnxIpi8Qk5VKdHzLHvkrdGXGFMzao6bReXX3KNrYrurAgd7fD2TAQo8EH5rgB7ewxtCIlHRoXJPSdVKpTPwx4c7Mfu2EMpx66pAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAPKMCK6mlLIFxMvIa4lT3fYY+APPhMazHtiPJ+279dkhzGmugD3x+mWvd+OzdmWlW/bvZWLbG3UXA166FK8ZcYyuTYdhCxP3vRNqBWNC65qURnIYyUK2DT09WrvBWLZqhv/mJFfijnGqvkKA1k3rVtgCGNDEnezmC9uuO8P17y3+/RZY8dBfvd8lkdCyTCFnKHNyKAE83qnqAJwgbc7cv7IKwAYsDdr4u38GFayBdTzCatTVrQDTYZbJDJLx+BcvHw8pdhthsX7wpGbFH5++Y5G4hRF2vGenzLFIHthxFnpgiZO3VjloPB57awA4jmJY9DjsOZNhZT+RbnCO9AQlCZE=\n-----END CERTIFICATE-----" // swiftlint:disable:this line_length
  let incorrectCertificate = "-----BEGIN CERTIFICATE-----\nMIIDATCCAemgAwIBAgIJAO+h3vH3X1puMA0GCSqGSIb3DQEBCwUAMBcxFTATBgNV\nBAMMDGZhY2Vib29rLmNvbTAeFw0yMDExMTAwMTUzMTFaFw0yMTA1MDkwMTUzMTFa\nMBcxFTATBgNVBAMMDGZhY2Vib29rLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEP\nADCCAQoCggEBAOZH/FVV1nsdlg6vhjuQlK8VYbN7F+aFAnkMFKQV+MQ88qj/zyBS\nAGZy5MTB3zHjCjw0IhJxTYoESxLy12T7UWqM7ltyKgEO0d8lLbIXR07QWziMd1Q+\n1AlTG9Yj6cMzQGFceB9x09MrOz/Gg+YrIzuRI2TXCaDW7j4LBhqLAlVrK8aMOVHJ\nFDWVCxuwdSNuJ+FNo/bvUqAWVQtn7KNoOcbot5Y4KAVQ16nufH0dJtRcOHzNELYB\nbxmtLWC8eKNn3H8Yw4whZV2BCVZJ/dQ1HZVlSktSs1wE5amg4wm3rHffyN1fpTah\nvN6bjMCQHrpBH2r0BSrkai/joh2ZeWZC068CAwEAAaNQME4wHQYDVR0OBBYEFIYZ\nJeio2kloli49hq+idEeGz3WwMB8GA1UdIwQYMBaAFIYZJeio2kloli49hq+idEeG\nz3WwMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBADU9ODtwRL7YDCJ6\naem7juewkgnXx48Tzcl6JtJijIl+IK0Phzb9r/GYrSC+H/N5rWCK5Ur55owXidb9\nXuLysM9xfHBUv91BK03XpevA0bwXCfRk0KPgyc744b8Qb636QiUOzF2aQTYxXbSF\nmXj1HdREsKow0202LfhjKtQWbL+7Q3lpiOFFOkkEVCBu42LT/Ix8VuL/RF3I2xS0\nBhO7FK6Y+ppw33lcmwfP7lLROpeowZA1WeF6tDsqBYivGg8G+9abAMnW0s4ZZSGD\ncDpGIcIlBRhr4nNo0u11BYuxcY8fukYkHvDYygrNhLVNme7JO3Iix7SOyxeMgT9t\ntBi+u9M=\n-----END CERTIFICATE-----" // swiftlint:disable:this line_length
  let encodedHeader = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9"
  let encodedClaims = "eyJzdWIiOiIxMjM0IiwibmFtZSI6IlRlc3QgVXNlciIsImlzcyI6Imh0dHBzOi8vZmFjZWJvb2suY29tL2RpYWxvZy9vYXV0aCIsImF1ZCI6IjQzMjEiLCJub25jZSI6InNvbWVfbm9uY2UiLCJleHAiOjE1MTYyNTkwMjIsImVtYWlsIjoiZW1haWxAZW1haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vd3d3LmZhY2Vib29rLmNvbS9zb21lX3BpY3R1cmUiLCJpYXQiOjE1MTYyMzkwMjJ9" // swiftlint:disable:this line_length
  let signature = "rTaqfx5Dz0UbzxZ3vBhitgtetWKBJ3-egz5n6l4ngLYqQ7ywapDvS7cM1NRGAh9drT8QeoxKPm0H_1B1LJBNyx-Fiseetfs7XANuocwTx9k7so3bi_EW0V-RYoDTgg5asS9Ra2qYM829xMYkhBHXp1HwHo0uHz1tafQ1hTsxtzH29t23_EnPpnVx5jvu-UeAEL4Q7VeIIfkweQYzuT3cowWAs-Vhyvl9I39Z4Uh_3ZhkpBJW1CblPW3ekHoySC61qwePM9Fk0q3N7K45LtktIMR5biV0RvJceTGOssHGhjaQ3hzpRq318MZKfBtg6C-Ryhh8SmOkuDrrj-VNdoVHKg" // swiftlint:disable:this line_length
  let certificateKey = "some_key"

  let sampleURL = URL(string: "https://example.com")! // swiftlint:disable:this force_unwrapping

  // MARK: - Creation

  func testCreateWithInvalidFormatToken() {
    var wasCalled = false
    var capturedAuthenticationToken: AuthenticationToken?
    let completion: AuthenticationTokenBlock = { token in
      capturedAuthenticationToken = token
      wasCalled = true
    }

    AuthenticationTokenFactory().createToken(
      tokenString: "invalid_token",
      nonce: "123456789",
      graphDomain: "facebook",
      completion: completion
    )

    XCTAssertNil(capturedAuthenticationToken)
    XCTAssertTrue(wasCalled, "Completion handler should be called synchronously")
  }

  // MARK: - Verifying Signature

  func testCertificateEndpointURL() {
    let url = AuthenticationTokenFactory().certificateEndpoint
    XCTAssertEqual(url.absoluteString, "https://m.facebook.com/.well-known/oauth/openid/certs/")
  }

  func testVerifySignatureWithoutDataWithoutResponseWithoutError() {
    let dataTask = TestSessionDataTask()
    let session = TestSessionProvider()
    session.stubbedDataTask = dataTask
    let factory = AuthenticationTokenFactory(sessionProvider: session)

    var wasCalled = false
    var capturedSuccess = false
    factory.verifySignature(
      signature,
      header: encodedHeader,
      claims: encodedClaims,
      certificateKey: certificateKey
    ) { success in
      capturedSuccess = success
      wasCalled = true
    }

    XCTAssertEqual(
      dataTask.resumeCallCount,
      1,
      "Should start the session data task when verifying a signature"
    )
    session.capturedCompletion?(nil, nil, nil)

    XCTAssertFalse(
      capturedSuccess,
      "A signature cannot be verified if the certificate request returns no data"
    )
    XCTAssertTrue(wasCalled)
  }

  func testVerifySignatureWithDataWithInvalidResponseWithoutError() {
    let dataTask = TestSessionDataTask()
    let session = TestSessionProvider()
    session.stubbedDataTask = dataTask
    let factory = AuthenticationTokenFactory(sessionProvider: session)

    var wasCalled = false
    var capturedSuccess = false
    factory.verifySignature(
      signature,
      header: encodedHeader,
      claims: encodedClaims,
      certificateKey: certificateKey
    ) { success in
      capturedSuccess = success
      wasCalled = true
    }

    XCTAssertEqual(
      dataTask.resumeCallCount,
      1,
      "Should start the session data task when verifying a signature"
    )

    session.capturedCompletion?(
      "foo".data(using: .utf8),
      HTTPURLResponse(url: sampleURL, statusCode: 401, httpVersion: nil, headerFields: nil),
      nil
    )

    XCTAssertFalse(
      capturedSuccess,
      "A signature cannot be verified if the certificate request returns a non-200 response"
    )
    XCTAssertTrue(wasCalled)
  }

  func testVerifySignatureWithInvalidDataWithValidResponseWithoutError() {
    let dataTask = TestSessionDataTask()
    let session = TestSessionProvider()
    session.stubbedDataTask = dataTask
    let factory = AuthenticationTokenFactory(sessionProvider: session)

    var wasCalled = false
    var capturedSuccess = false
    factory.verifySignature(
      signature,
      header: encodedHeader,
      claims: encodedClaims,
      certificateKey: certificateKey
    ) { success in
      capturedSuccess = success
      wasCalled = true
    }

    XCTAssertEqual(
      dataTask.resumeCallCount,
      1,
      "Should start the session data task when verifying a signature"
    )

    session.capturedCompletion?(
      "foo".data(using: .utf8),
      HTTPURLResponse(url: sampleURL, statusCode: 401, httpVersion: nil, headerFields: nil),
      nil
    )
    XCTAssertFalse(
      capturedSuccess,
      "A signature cannot be verified if the certificate request returns invalid data"
    )
    XCTAssertTrue(wasCalled)
  }

  func testVerifySignatureWithValidDataWithValidResponseWithError() throws {
    let dataTask = TestSessionDataTask()
    let session = TestSessionProvider()
    session.stubbedDataTask = dataTask
    let factory = AuthenticationTokenFactory(sessionProvider: session)

    var wasCalled = false
    var capturedSuccess = false
    factory.verifySignature(
      signature,
      header: encodedHeader,
      claims: encodedClaims,
      certificateKey: certificateKey
    ) { success in
      capturedSuccess = success
      wasCalled = true
    }

    XCTAssertEqual(
      dataTask.resumeCallCount,
      1,
      "Should start the session data task when verifying a signature"
    )

    session.capturedCompletion?(
      try createValidCertificateData(),
      HTTPURLResponse(url: sampleURL, statusCode: 200, httpVersion: nil, headerFields: nil),
      SampleError()
    )

    XCTAssertFalse(
      capturedSuccess,
      "A signature cannot be verified if the certificate request returns an error"
    )
    XCTAssertTrue(wasCalled)
  }

  func testVerifySignatureWithValidDataWithValidResponseWithoutError() throws {
    let dataTask = TestSessionDataTask()
    let session = TestSessionProvider()
    session.stubbedDataTask = dataTask
    let factory = AuthenticationTokenFactory(sessionProvider: session)

    var wasCalled = false
    var capturedSuccess = false
    factory.verifySignature(
      signature,
      header: encodedHeader,
      claims: encodedClaims,
      certificateKey: certificateKey
    ) { success in
      capturedSuccess = success
      wasCalled = true
    }

    XCTAssertEqual(
      dataTask.resumeCallCount,
      1,
      "Should start the session data task when verifying a signature"
    )
    session.capturedCompletion?(
      try createValidCertificateData(),
      HTTPURLResponse(url: sampleURL, statusCode: 200, httpVersion: nil, headerFields: nil),
      nil
    )

    XCTAssertTrue(
      capturedSuccess,
      "Should verify a signature when the response contains the expected key"
    )
    XCTAssertTrue(wasCalled)
  }

  func testVerifySignatureWithInvalidCertificates() throws {
    let certificates = [
      try createMangledCertificateData(),
      try createValidIncorrectCertificateData(),
    ]

    certificates.forEach { certificateData in
      let dataTask = TestSessionDataTask()
      let session = TestSessionProvider()
      session.stubbedDataTask = dataTask
      let factory = AuthenticationTokenFactory(sessionProvider: session)

      var wasCalled = false
      var capturedSuccess = false
      factory.verifySignature(
        signature,
        header: encodedHeader,
        claims: encodedClaims,
        certificateKey: certificateKey
      ) { success in
        capturedSuccess = success
        wasCalled = true
      }

      XCTAssertEqual(
        dataTask.resumeCallCount,
        1,
        "Should start the session data task when verifying a signature"
      )

      session.capturedCompletion?(
        certificateData,
        HTTPURLResponse(url: sampleURL, statusCode: 200, httpVersion: nil, headerFields: nil),
        nil
      )
      XCTAssertFalse(
        capturedSuccess,
        "Should not verify a signature for an incorrect or invalid certificate"
      )
      XCTAssertTrue(wasCalled)
    }
  }

  func testVerifySignatureWithFuzzyData() throws {
    let dataTask = TestSessionDataTask()
    let session = TestSessionProvider()
    session.stubbedDataTask = dataTask
    let factory = AuthenticationTokenFactory(sessionProvider: session)

    try (1 ..< 100).forEach { _ in
      let certificates = Fuzzer.randomize(json: validRawCertificateResponse)
      var wasCalled = false
      factory.verifySignature(
        signature,
        header: encodedHeader,
        claims: encodedClaims,
        certificateKey: certificateKey
      ) { _ in
        wasCalled = true
      }
      if JSONSerialization.isValidJSONObject(certificates) {
        session.capturedCompletion?(
          try JSONSerialization.data(withJSONObject: certificates, options: []),
          HTTPURLResponse(url: sampleURL, statusCode: 200, httpVersion: nil, headerFields: nil),
          nil
        )
        XCTAssertTrue(wasCalled)
      }
    }
  }

  // MARK: - Helpers

  var validRawCertificateResponse: [String: Any] {
    [
      certificateKey: certificate,
      "foo": "Not a certificate",
    ]
  }

  func createMangledCertificateData() throws -> Data {
    let object = [
      certificateKey: certificate.replacingOccurrences(of: "a", with: "b"),
    ]

    return try JSONSerialization.data(withJSONObject: object, options: [])
  }

  func createValidCertificateData() throws -> Data {
    try JSONSerialization.data(withJSONObject: validRawCertificateResponse, options: [])
  }

  func createValidIncorrectCertificateData() throws -> Data {
    let certificates = [
      certificateKey: incorrectCertificate,
    ]
    return try JSONSerialization.data(withJSONObject: certificates, options: [])
  }
}
