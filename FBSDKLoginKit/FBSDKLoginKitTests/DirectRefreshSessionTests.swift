/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
@testable import FBSDKLoginKit

import Foundation
import Security
import TestTools
import XCTest

@available(iOS 13.0, *)
final class DirectRefreshSessionTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  private var session: URLSession!
  private var settings: TestSettings!
  private var privateKey: SecKey!
  private var publicKeyJWK: [String: String]!
  private var directRefresh: DirectRefreshSession!
  // swiftlint:enable implicitly_unwrapped_optional

  // Default stub URL used by `makeRefreshSession()`. Individual tests can
  // override by passing a different builder to `makeRefreshSession(urlBuilder:)`.
  // swiftlint:disable:next force_unwrapping
  private static let stubURL = URL(string: "https://limited.facebook.com/limited_login/refresh/")!

  // Captures the (hostPrefix, path) passed to the URL builder so tests can
  // assert on them without touching `Settings.shared` (which would fatal
  // unless the SDK is initialized).
  private var capturedHostPrefix: String?
  private var capturedPath: String?

  override func setUp() {
    super.setUp()
    StubURLProtocol.reset()
    capturedHostPrefix = nil
    capturedPath = nil

    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [StubURLProtocol.self]
    session = URLSession(configuration: config)

    settings = TestSettings()
    settings.appID = "1234567890"
    settings.graphAPIVersion = "v22.0"

    let attrs: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256,
      kSecPrivateKeyAttrs as String: [kSecAttrIsPermanent as String: false] as [String: Any],
    ]
    var error: Unmanaged<CFError>?
    privateKey = SecKeyCreateRandomKey(attrs as CFDictionary, &error)
    publicKeyJWK = DPoPKeyManager.publicKeyJWK(for: privateKey)

    directRefresh = makeRefreshSession()
  }

  override func tearDown() {
    StubURLProtocol.reset()
    directRefresh = nil
    publicKeyJWK = nil
    privateKey = nil
    settings = nil
    session = nil
    super.tearDown()
  }

  private func makeRefreshSession(
    provideKeys: Bool = true,
    stubbedURL: URL = stubURL
  ) -> DirectRefreshSession {
    DirectRefreshSession(
      session: session,
      settings: settings,
      keyMaterialProvider: { [privateKey, publicKeyJWK] in
        guard provideKeys,
              let key = privateKey,
              let jwk = publicKeyJWK
        else { return nil }

        return (key, jwk)
      },
      urlBuilder: { [weak self] hostPrefix, path in
        self?.capturedHostPrefix = hostPrefix
        self?.capturedPath = path
        return stubbedURL
      }
    )
  }

  // MARK: - Success

  func testSuccessfulRefreshReturnsIdToken() {
    StubURLProtocol.stubbedData = try? JSONSerialization.data(
      withJSONObject: ["id_token": "fresh.id.token"]
    )

    let exp = expectation(description: "completion")
    directRefresh.refresh(idTokenHint: "old.token", appID: "1234567890") { result in
      if case let .success(idToken) = result {
        XCTAssertEqual(idToken, "fresh.id.token")
      } else {
        XCTFail("Expected success, got \(result)")
      }
      exp.fulfill()
    }
    wait(for: [exp], timeout: 5)
  }

  // MARK: - Server errors

  func testLoginRequiredErrorMapsToLoginRequired() {
    assertServerErrorMaps(code: "login_required", to: .loginRequired)
  }

  func testConsentRequiredErrorMapsToConsentRequired() {
    assertServerErrorMaps(code: "consent_required", to: .consentRequired)
  }

  func testInvalidDpopProofErrorMapsToLoginRequired() {
    assertServerErrorMaps(code: "invalid_dpop_proof", to: .loginRequired)
  }

  func testUnknownServerErrorMapsToUnknown() {
    assertServerErrorMaps(code: "wat_is_this_error", to: .unknown)
  }

  // MARK: - Network / parse failures

  func testNetworkErrorReturnsNetworkError() {
    StubURLProtocol.stubbedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)

    let exp = expectation(description: "completion")
    directRefresh.refresh(idTokenHint: "x", appID: "1234567890") { result in
      if case let .failure(err) = result {
        XCTAssertEqual(err, .networkError)
      } else {
        XCTFail("Expected network error, got \(result)")
      }
      exp.fulfill()
    }
    wait(for: [exp], timeout: 5)
  }

  func testMalformedResponseReturnsInvalidResponse() {
    StubURLProtocol.stubbedData = Data("not json".utf8)

    let exp = expectation(description: "completion")
    directRefresh.refresh(idTokenHint: "x", appID: "1234567890") { result in
      if case let .failure(err) = result {
        XCTAssertEqual(err, .invalidResponse)
      } else {
        XCTFail("Expected invalidResponse, got \(result)")
      }
      exp.fulfill()
    }
    wait(for: [exp], timeout: 5)
  }

  func testEmptyResponseBodyReturnsInvalidResponse() {
    StubURLProtocol.stubbedData = nil

    let exp = expectation(description: "completion")
    directRefresh.refresh(idTokenHint: "x", appID: "1234567890") { result in
      if case let .failure(err) = result {
        XCTAssertEqual(err, .invalidResponse)
      } else {
        XCTFail("Expected invalidResponse, got \(result)")
      }
      exp.fulfill()
    }
    wait(for: [exp], timeout: 5)
  }

  // MARK: - Request shape

  func testDPoPHeaderIsPresentInRequest() {
    StubURLProtocol.stubbedData = try? JSONSerialization.data(
      withJSONObject: ["id_token": "x.y.z"]
    )

    let exp = expectation(description: "completion")
    directRefresh.refresh(idTokenHint: "old.token", appID: "1234567890") { _ in exp.fulfill() }
    wait(for: [exp], timeout: 5)

    let dpop = StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "DPoP")
    XCTAssertNotNil(dpop)
    XCTAssertEqual(dpop?.split(separator: ".").count, 3)
    XCTAssertEqual(
      StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Content-Type"),
      "application/x-www-form-urlencoded"
    )
    XCTAssertEqual(StubURLProtocol.lastRequest?.httpMethod, "POST")
  }

  func testRequestBodyContainsIdTokenHintAndAppId() throws {
    StubURLProtocol.stubbedData = try? JSONSerialization.data(
      withJSONObject: ["id_token": "x.y.z"]
    )

    let exp = expectation(description: "completion")
    directRefresh.refresh(idTokenHint: "old.token", appID: "1234567890") { _ in exp.fulfill() }
    wait(for: [exp], timeout: 5)

    let body = try XCTUnwrap(StubURLProtocol.lastBody)
    let bodyString = try XCTUnwrap(String(data: body, encoding: .utf8))
    let parsed = Self.parseFormURLEncoded(bodyString)
    XCTAssertEqual(parsed["id_token_hint"], "old.token")
    XCTAssertEqual(parsed["app_id"], "1234567890")
  }

  func testRequestUsesLimitedHostPrefixAndRefreshPath() throws {
    StubURLProtocol.stubbedData = try? JSONSerialization.data(
      withJSONObject: ["id_token": "x.y.z"]
    )

    let exp = expectation(description: "completion")
    directRefresh.refresh(idTokenHint: "x", appID: "1234567890") { _ in exp.fulfill() }
    wait(for: [exp], timeout: 5)

    XCTAssertEqual(capturedHostPrefix, LoginEndpoints.limitedHostPrefix)
    XCTAssertEqual(capturedPath, "/limited_login/refresh/")
  }

  func testRequestHitsURLProvidedByURLBuilder() throws {
    // Simulates an OD/sandbox build where Settings.facebookDomainPart causes
    // Utility.unversionedFacebookURL to inject the domain part into the host.
    // The request must hit that host, not the prod fallback.
    let stubbedURL = try XCTUnwrap(
      URL(string: "https://limited.55117.od.facebook.com/limited_login/refresh/")
    )
    directRefresh = makeRefreshSession(stubbedURL: stubbedURL)

    StubURLProtocol.stubbedData = try? JSONSerialization.data(
      withJSONObject: ["id_token": "x.y.z"]
    )

    let exp = expectation(description: "completion")
    directRefresh.refresh(idTokenHint: "x", appID: "1234567890") { _ in exp.fulfill() }
    wait(for: [exp], timeout: 5)

    XCTAssertEqual(StubURLProtocol.lastRequest?.url, stubbedURL)
  }

  func testDPoPProofHtuMatchesRequestURL() throws {
    // The DPoP server validates that the proof's `htu` claim equals the URL
    // the request was made to. If the proof is built against a hardcoded prod
    // URL while the request goes to an OD host, the server rejects with
    // `invalid_dpop_proof`.
    let stubbedURL = try XCTUnwrap(
      URL(string: "https://limited.55117.od.facebook.com/limited_login/refresh/")
    )
    directRefresh = makeRefreshSession(stubbedURL: stubbedURL)

    StubURLProtocol.stubbedData = try? JSONSerialization.data(
      withJSONObject: ["id_token": "x.y.z"]
    )

    let exp = expectation(description: "completion")
    directRefresh.refresh(idTokenHint: "x", appID: "1234567890") { _ in exp.fulfill() }
    wait(for: [exp], timeout: 5)

    let dpop = try XCTUnwrap(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "DPoP"))
    let payloadSegment = try XCTUnwrap(dpop.split(separator: ".").dropFirst().first.map(String.init))
    let payloadData = try XCTUnwrap(Self.base64URLDecode(payloadSegment))
    let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: payloadData) as? [String: Any])
    XCTAssertEqual(payload["htu"] as? String, stubbedURL.absoluteString)
  }

  func testFailureToBuildURLReturnsInvalidResponse() {
    directRefresh = DirectRefreshSession(
      session: session,
      settings: settings,
      keyMaterialProvider: { [privateKey, publicKeyJWK] in
        guard let key = privateKey,
              let jwk = publicKeyJWK
        else { return nil }

        return (key, jwk)
      },
      urlBuilder: { _, _ in nil }
    )

    let exp = expectation(description: "completion")
    directRefresh.refresh(idTokenHint: "x", appID: "1234567890") { result in
      if case let .failure(err) = result {
        XCTAssertEqual(err, .invalidResponse)
      } else {
        XCTFail("Expected invalidResponse, got \(result)")
      }
      exp.fulfill()
    }
    wait(for: [exp], timeout: 5)
  }

  func testCompletionFiresOnMainQueue() {
    // URLSession's data-task callbacks run on a background queue. Hackbook
    // (and any app caller) updates UIKit from this completion, which would
    // crash on a background thread. Regression test for that crash.
    StubURLProtocol.stubbedData = try? JSONSerialization.data(
      withJSONObject: ["id_token": "x.y.z"]
    )

    let exp = expectation(description: "completion")
    directRefresh.refresh(idTokenHint: "x", appID: "1234567890") { _ in
      XCTAssertTrue(Thread.isMainThread, "Completion must fire on the main queue.")
      exp.fulfill()
    }
    wait(for: [exp], timeout: 5)
  }

  // MARK: - Missing key material

  func testMissingPrivateKeyReturnsLoginRequired() {
    directRefresh = makeRefreshSession(provideKeys: false)

    let exp = expectation(description: "completion")
    directRefresh.refresh(idTokenHint: "x", appID: "1234567890") { result in
      if case let .failure(err) = result {
        XCTAssertEqual(err, .loginRequired)
      } else {
        XCTFail("Expected loginRequired, got \(result)")
      }
      exp.fulfill()
    }
    wait(for: [exp], timeout: 5)
  }

  // MARK: - Helpers

  private func assertServerErrorMaps(
    code: String,
    to expected: LimitedLoginRefreshError,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    StubURLProtocol.stubbedData = try? JSONSerialization.data(
      withJSONObject: ["error": code]
    )

    let exp = expectation(description: "completion")
    directRefresh.refresh(idTokenHint: "x", appID: "1234567890") { result in
      if case let .failure(err) = result {
        XCTAssertEqual(err, expected, file: file, line: line)
      } else {
        XCTFail("Expected failure, got \(result)", file: file, line: line)
      }
      exp.fulfill()
    }
    wait(for: [exp], timeout: 5)
  }

  private static func parseFormURLEncoded(_ body: String) -> [String: String] {
    var components = URLComponents()
    components.percentEncodedQuery = body
    var result: [String: String] = [:]
    for item in components.queryItems ?? [] {
      result[item.name] = item.value
    }
    return result
  }

  private static func base64URLDecode(_ string: String) -> Data? {
    var padded = string.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    while padded.count % 4 != 0 { padded.append("=") }
    return Data(base64Encoded: padded)
  }
}
