/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

class AppLinkResolverTests: XCTestCase {
  enum Keys {
    static let appLinkURL = URL(string: "http://example.com/1234567890")! // swiftlint:disable:this force_unwrapping
    static let appLinkURL2 = URL(string: "http://example.com/0987654321")! // swiftlint:disable:this force_unwrapping
    static let appLinks = "app_links"
    static let iPhone = "iphone"
    static let iPad = "ipad"
    static let ios = "ios"
    static let android = "android"
    static let id = "id" // swiftlint:disable:this identifier_name
    static let appName = "app_name"
    static let appStoreId = "app_store_id"
    static let package = "package"
    static let url = "url"
    static let web = "web"
    static let shouldFallback = "should_fallback"
  }

  enum Values {
    static let appName = "Example"
    static let appStoreId = "123"
    static let appStoreId2 = "456"
    static let url = "example://things/1234567890"
    static let fallbackURL = "http://www.example.com/somethingelse"
    static let package = "com.example.app"
    static let `true` = "true"
    static let `false` = "false"
  }

  let linkValues1 = [
    Keys.appName: Values.appName,
    Keys.appStoreId: Values.appStoreId,
    Keys.url: Values.url
  ]
  let linkValues2 = [
    Keys.appName: Values.appName,
    Keys.appStoreId: Values.appStoreId2,
    Keys.url: Values.url
  ]
  let androidLinkValues = [
    Keys.appName: Values.appName,
    Keys.package: Values.package,
    Keys.url: Values.url
  ]

  let queryParameters = [String: String]()

  let builder = TestAppLinkResolverRequestBuilder()
  let clientTokenProvider = TestClientTokenProvider(clientToken: "clienttoken")
  let accessTokenProvider = TestAccessTokenWallet.self
  let graphRequest = TestGraphRequest()
  var resolved: AppLink?
  var error: Error?

  lazy var resolver = AppLinkResolver(
    userInterfaceIdiom: .phone,
    requestBuilder: builder,
    clientTokenProvider: clientTokenProvider,
    accessTokenProvider: accessTokenProvider
  )

  override func setUp() {
    super.setUp()

    builder.stubbedGraphRequest = graphRequest
  }

  override func tearDown() {
    super.tearDown()

    TestAccessTokenWallet.reset()
  }

  func testDefaultDependecies() {
    resolver = AppLinkResolver(userInterfaceIdiom: .phone)
    XCTAssertTrue(resolver.requestBuilder is AppLinkResolverRequestBuilder)
    XCTAssertTrue(resolver.clientTokenProvider === Settings.shared)
    XCTAssertTrue(resolver.accessTokenProvider is AccessToken.Type)
  }

  func testResolvingWithPhoneIdiom() {
    builder.stubbedIdiomSpecificField = Keys.iPhone

    let result = [
      Keys.appLinkURL.absoluteString: [
        Keys.appLinks: [
          Keys.iPhone: [linkValues2],
          Keys.ios: [linkValues1]
        ],
        Keys.id: Keys.appLinkURL.absoluteString
      ]
    ]

    resolver.appLink(from: Keys.appLinkURL) {
      self.resolved = $0
      self.error = $1
    }

    graphRequest.capturedCompletionHandler?(nil, result, nil)

    XCTAssertNil(error)

    guard let link = resolved else {
      return XCTFail("Must have a resolved app link")
    }
    XCTAssertEqual(link.sourceURL, Keys.appLinkURL)
    XCTAssertEqual(link.targets[0].appStoreId, Values.appStoreId2)
    XCTAssertEqual(link.targets[1].appStoreId, Values.appStoreId)
  }

  func testResolvingWithPadIdiom() {
    builder.stubbedIdiomSpecificField = Keys.iPad

    let result = [
      Keys.appLinkURL.absoluteString: [
        Keys.appLinks: [
          Keys.iPad: [linkValues2],
          Keys.ios: [linkValues1]
        ],
        Keys.id: Keys.appLinkURL.absoluteString
      ]
    ]

    resolver.appLink(from: Keys.appLinkURL) {
      self.resolved = $0
      self.error = $1
    }

    graphRequest.capturedCompletionHandler?(nil, result, nil)

    XCTAssertNil(error)

    guard let link = resolved else {
      return XCTFail("Must have a resolved app link")
    }
    XCTAssertEqual(link.sourceURL, Keys.appLinkURL)
    XCTAssertEqual(link.targets[0].appStoreId, Values.appStoreId2)
    XCTAssertEqual(link.targets[1].appStoreId, Values.appStoreId)
  }

  func testResolvingIgnoresAndroidLinks() {
    builder.stubbedIdiomSpecificField = Keys.iPad

    let result = [
      Keys.appLinkURL.absoluteString: [
        Keys.appLinks: [
          Keys.android: [androidLinkValues],
          Keys.ios: [linkValues1]
        ],
        Keys.id: Keys.appLinkURL.absoluteString
      ]
    ]

    resolver.appLink(from: Keys.appLinkURL) {
      self.resolved = $0
      self.error = $1
    }

    graphRequest.capturedCompletionHandler?(nil, result, nil)

    XCTAssertNil(error)
    XCTAssertEqual(resolved?.targets[0].appStoreId, Values.appStoreId)
  }

  func testResolvingWithoutTargets() {
    builder.stubbedIdiomSpecificField = Keys.iPad

    let result = [
      Keys.appLinkURL.absoluteString: [
        Keys.id: Keys.appLinkURL.absoluteString
      ]
    ]

    resolver.appLink(from: Keys.appLinkURL) {
      self.resolved = $0
      self.error = $1
    }

    graphRequest.capturedCompletionHandler?(nil, result, nil)

    XCTAssertNil(error)

    guard let link = resolved else {
      return XCTFail("Must have a resolved app link")
    }
    XCTAssertEqual(link.sourceURL, Keys.appLinkURL)
    XCTAssertTrue(link.targets.isEmpty)
  }

  func testResolvingWithMultipleURLs() {
    builder.stubbedIdiomSpecificField = Keys.iPad

    let result = [
      Keys.appLinkURL.absoluteString: [
        Keys.id: Keys.appLinkURL.absoluteString
      ],
      Keys.appLinkURL2.absoluteString: [
        Keys.id: Keys.appLinkURL2.absoluteString
      ]
    ]

    var resolved: [URL: AppLink]?
    var error: Error?
    resolver.appLinks(from: [Keys.appLinkURL, Keys.appLinkURL2]) {
      resolved = $0
      error = $1
    }

    graphRequest.capturedCompletionHandler?(nil, result, nil)

    XCTAssertNil(error)

    guard let links = resolved else {
      return XCTFail("Must have a resolved app link")
    }
    XCTAssertEqual(links.count, 2)
    XCTAssertEqual(links[Keys.appLinkURL]?.sourceURL, Keys.appLinkURL)
    XCTAssertEqual(links[Keys.appLinkURL2]?.sourceURL, Keys.appLinkURL2)
  }

  func testResolvingSetsFallbackIfNotSpecified() {
    builder.stubbedIdiomSpecificField = Keys.iPad

    let result = [
      Keys.appLinkURL.absoluteString: [
        Keys.id: Keys.appLinkURL.absoluteString
      ]
    ]

    resolver.appLink(from: Keys.appLinkURL) {
      self.resolved = $0
      self.error = $1
    }

    graphRequest.capturedCompletionHandler?(nil, result, nil)

    XCTAssertNil(error)

    guard let link = resolved else {
      return XCTFail("Must have a resolved app link")
    }
    XCTAssertEqual(link.webURL, Keys.appLinkURL)
  }

  func testResolvingSetsFallbackIfSpecified() throws {
    builder.stubbedIdiomSpecificField = Keys.iPad

    let result = [
      Keys.appLinkURL.absoluteString: [
        Keys.appLinks: [
          Keys.web: [
            Keys.url: Values.fallbackURL,
            Keys.shouldFallback: Values.true
          ]
        ],
        Keys.id: Keys.appLinkURL.absoluteString
      ]
    ]

    resolver.appLink(from: Keys.appLinkURL) {
      self.resolved = $0
      self.error = $1
    }

    graphRequest.capturedCompletionHandler?(nil, result, nil)

    XCTAssertNil(error)

    XCTAssertEqual(resolved?.webURL?.absoluteString, Values.fallbackURL)
  }

  func testResolvingUsesSourceAsFallbackIfSpecified() throws {
    builder.stubbedIdiomSpecificField = Keys.iPad

    let result = [
      Keys.appLinkURL.absoluteString: [
        Keys.appLinks: [
          Keys.web: [
            Keys.shouldFallback: Values.true
          ]
        ],
        Keys.id: Keys.appLinkURL.absoluteString
      ]
    ]

    resolver.appLink(from: Keys.appLinkURL) {
      self.resolved = $0
      self.error = $1
    }

    graphRequest.capturedCompletionHandler?(nil, result, nil)

    XCTAssertNil(error)

    XCTAssertEqual(resolved?.webURL, Keys.appLinkURL)
  }

  func testResolvingSetsNoFallbackIfSpecified() throws {
    builder.stubbedIdiomSpecificField = Keys.iPad

    let result = [
      Keys.appLinkURL.absoluteString: [
        Keys.appLinks: [
          Keys.web: [
            Keys.url: Values.fallbackURL,
            Keys.shouldFallback: Values.false
          ]
        ],
        Keys.id: Keys.appLinkURL.absoluteString
      ]
    ]

    resolver.appLink(from: Keys.appLinkURL) {
      self.resolved = $0
      self.error = $1
    }

    graphRequest.capturedCompletionHandler?(nil, result, nil)

    XCTAssertNil(error)
    XCTAssertNil(resolved?.webURL)
  }

  func testResolvingWithError() {

    resolver.appLink(from: Keys.appLinkURL) {
      self.resolved = $0
      self.error = $1
    }

    graphRequest.capturedCompletionHandler?(nil, nil, SampleError())

    XCTAssertNotNil(error)
    XCTAssertNil(resolved)
  }

  func testReadsFromCache() {
    let link = AppLink(sourceURL: Keys.appLinkURL, targets: [], webURL: nil)
    resolver.cachedAppLinks = [Keys.appLinkURL: link]

    resolver.appLink(from: Keys.appLinkURL) {
      self.resolved = $0
      self.error = $1
    }

    XCTAssertNil(graphRequest.capturedCompletionHandler)
    XCTAssertNil(error)
    XCTAssertEqual(resolved, link)
  }

  func testSetsCache() throws {
    let result = [
      Keys.appLinkURL.absoluteString: [
        Keys.id: Keys.appLinkURL.absoluteString
      ]
    ]

    resolver.appLink(from: Keys.appLinkURL) { _, _ in }

    graphRequest.capturedCompletionHandler?(nil, result, nil)

    XCTAssertNotNil(resolver.cachedAppLinks[Keys.appLinkURL])
  }
}
