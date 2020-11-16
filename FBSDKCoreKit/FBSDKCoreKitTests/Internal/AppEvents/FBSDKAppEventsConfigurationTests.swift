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

class FBSDKAppEventsConfigurationTests: XCTestCase {
  typealias Fixtures = FBSDKAppEventsConfigurationFixtures

  private var config = Fixtures.defaultConfig()

  override func setUp() {
    super.setUp()
    config = Fixtures.defaultConfig()
  }

  func testCreatingWithDefaultATEStatus() {
    XCTAssertEqual(config.defaultATEStatus, .unspecified, "Default ATE Status should be unspecified")
  }

  func testCreatingWithKnownDefaultATEStatus() {
    config = Fixtures.config(with: ["default_ate_status": AppEventsUtility.AdvertisingTrackingStatus.allowed.rawValue])
    XCTAssertEqual(config.defaultATEStatus, .allowed, "Default ATE Status should be settable")
  }

  func testCreatingWithDefaultAdvertisingIDCollectionEnabled() {
    XCTAssertTrue(config.advertiserIDCollectionEnabled,
                  "Advertising identifier collection enabled should default to true")
  }

  func testCreatingWithKnownAdvertisingIDCollectionEnabled() {
    config = Fixtures.config(with: ["advertiser_id_collection_enabled": false])
    XCTAssertFalse(config.advertiserIDCollectionEnabled, "Advertising identifier collection enabled should be settable")
  }

  func testCreatingWithDefaultEventCollectionEnabled() {
    XCTAssertFalse(config.eventCollectionEnabled, "Event collection enabled should default to false")
  }

  func testCreatingWithKnownEventCollectionEnabled() {
    config = Fixtures.config(with: ["event_collection_enabled": true])
    XCTAssertTrue(config.eventCollectionEnabled, "Event collection enabled should be settable")
  }
}
