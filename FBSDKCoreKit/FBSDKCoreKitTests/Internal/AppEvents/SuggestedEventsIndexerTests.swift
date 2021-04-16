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

import XCTest

class SuggestedEventsIndexerTests: XCTestCase {

  let requestProvider = TestGraphRequestFactory()
  let settings = TestSettings()
  let eventLogger = TestEventLogger()
  var indexer: SuggestedEventsIndexer! // swiftlint:disable:this implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    SuggestedEventsIndexerTests.reset()

    indexer = SuggestedEventsIndexer(
      requestProvider: requestProvider,
      serverConfigurationProvider: TestServerConfigurationProvider.self,
      swizzler: TestSwizzler.self,
      settings: settings,
      eventLogger: eventLogger,
      featureExtractor: TestFeatureExtractor.self
    )
  }

  override class func tearDown() {
    super.tearDown()

    reset()
  }

  static func reset() {
    TestServerConfigurationProvider.reset()
    TestSwizzler.reset()
    TestFeatureExtractor.reset()
  }

  func testDefaultDependencies() {
    indexer = SuggestedEventsIndexer()

    XCTAssertTrue(
      indexer.requestProvider is GraphRequestFactory,
      "Should have a request provider of the expected default type"
    )
    XCTAssertTrue(
      indexer.serverConfigurationProvider is ServerConfigurationManager.Type,
      "Should have a server configuration manager of the expected default type"
    )
    XCTAssertTrue(
      indexer.swizzler is Swizzler.Type,
      "Should have a swizzler of the expected default type"
    )
    XCTAssertTrue(
      indexer.settings is Settings,
      "Should have a settings of the expected default type"
    )
    XCTAssertTrue(
      indexer.eventLogger is EventLogger,
      "Should have an event logger of the expected default type"
    )
  }

  func testCustomDependencies() {
    XCTAssertTrue(
      indexer.requestProvider is TestGraphRequestFactory,
      "Should be able to create an instance with a custom request provider"
    )
    XCTAssertTrue(
      indexer.serverConfigurationProvider is TestServerConfigurationProvider.Type,
      "Should be able to create an instance with a custom server configuration provider"
    )
    XCTAssertTrue(
      indexer.swizzler is TestSwizzler.Type,
      "Should be able to create an instance with a custom swizzer"
    )
    XCTAssertTrue(
      indexer.settings is TestSettings,
      "Should be able to create an instance with a custom settings"
    )
    XCTAssertTrue(
      indexer.eventLogger is TestEventLogger,
      "Should be able to create an instance with a custom event logger"
    )
  }
}
