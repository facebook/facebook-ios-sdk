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

class CodelessIndexerTests: XCTestCase {

  let requestFactory = TestGraphRequestFactory()
  let store = UserDefaultsSpy()
  let connection: TestGraphRequestConnection = TestGraphRequestConnection()
  lazy var connectionFactory: TestGraphRequestConnectionFactory = {
    return TestGraphRequestConnectionFactory.create(withStubbedConnection: connection)
  }()
  let settings = TestSettings()

  override func setUp() {
    super.setUp()

    CodelessIndexerTests.reset()

    CodelessIndexer.configure(
      withRequestProvider: requestFactory,
      serverConfigurationProvider: TestServerConfigurationProvider.self,
      store: store,
      connectionProvider: connectionFactory,
      swizzler: TestSwizzler.self,
      settings: settings
    )
  }

  override class func tearDown() {
    super.tearDown()

    reset()
  }

  class func reset() {
    CodelessIndexer.reset()
    TestSwizzler.reset()
    TestServerConfigurationProvider.reset()
  }

  // MARK: - Dependencies

  func testDefaultDependencies() {
    CodelessIndexer.reset()

    XCTAssertNil(
      CodelessIndexer.requestProvider,
      "Should not have a request provider by default"
    )
    XCTAssertNil(
      CodelessIndexer.serverConfigurationProvider,
      "Should not have a server configuration provider by default"
    )
    XCTAssertNil(
      CodelessIndexer.store,
      "Should not have a persistent data store by default"
    )
    XCTAssertNil(
      CodelessIndexer.connectionProvider,
      "Should not have a connection provider by default"
    )
    XCTAssertNil(
      CodelessIndexer.swizzler,
      "Should not have a swizzler by default"
    )
    XCTAssertNil(
      CodelessIndexer.settings,
      "Should not have a settings instance by default"
    )
  }

  func testConfiguringWithDependencies() {
    XCTAssertEqual(
      CodelessIndexer.requestProvider as? TestGraphRequestFactory,
      requestFactory,
      "Should be able to configure with a request provider"
    )
    XCTAssertTrue(
      CodelessIndexer.serverConfigurationProvider is TestServerConfigurationProvider.Type,
      "Should be able to configure with a server configuration provider"
    )
    XCTAssertEqual(
      CodelessIndexer.store as? UserDefaultsSpy,
      store,
      "Should be able to configure with a persistent data store"
    )
    XCTAssertEqual(
      CodelessIndexer.connectionProvider as? TestGraphRequestConnectionFactory,
      connectionFactory,
      "Should be able to configure with a connection provider"
    )
    XCTAssertTrue(
      CodelessIndexer.swizzler is TestSwizzler.Type,
      "Should be able to configure with a swizzler"
    )
    XCTAssertTrue(
      CodelessIndexer.settings is TestSettings,
      "Should be able to configure with a settings"
    )
  }
}
