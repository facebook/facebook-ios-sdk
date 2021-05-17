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

class FBSDKIntegrityManagerTests: XCTestCase {

  var isGateKeeperEnabled = Bool.random()
  let gatekeeperKey = "FBSDKFeatureIntegritySample"
  let processor = TestIntegrityProcessor()
  var manager: IntegrityManager! // swiftlint:disable:this implicitly_unwrapped_optional

  override class func setUp() {
    super.setUp()

    TestGateKeeperManager.reset()
  }

  override func setUp() {
    super.setUp()

    TestGateKeeperManager.gateKeepers[gatekeeperKey] = isGateKeeperEnabled
    manager = IntegrityManager(
      gateKeeperManager: TestGateKeeperManager.self,
      integrityProcessor: processor
    )
  }

  override func tearDown() {
    super.tearDown()

    TestGateKeeperManager.reset()
  }

  func testCreating() {
    XCTAssertTrue(
      manager.gateKeeperManager is TestGateKeeperManager.Type,
      "Should use the provided gatekeeper manager"
    )
    XCTAssertEqual(
      ObjectIdentifier(manager.integrityProcessor!), // swiftlint:disable:this force_unwrapping
      ObjectIdentifier(processor),
      "Should use the provided integrity processor"
    )
    XCTAssertFalse(
      manager.isIntegrityEnabled,
      "Should not enable integrity checks by default"
    )
    XCTAssertFalse(
      manager.isSampleEnabled,
      "Should not enable sampling by default"
    )
  }

  func testEnabling() {
    manager.enable()

    XCTAssertTrue(
      manager.isIntegrityEnabled,
      "Enabling should enable integrity checks"
    )
    XCTAssertEqual(
      manager.isSampleEnabled,
      isGateKeeperEnabled,
      "Enabling should set sampling to the value provided by the gatekeeper manager"
    )
  }

  // MARK: - Processing

  func testProcessingParametersWithRestrictedData() {
    manager.enable()

    let parameters = [
      "address": "2301 N Highland Ave, Los Angeles, CA 90068", // address
      "period_starts": "2020-02-03", // health
    ]

    processor.stubbedParameters = [
      "address": true,
      "period_starts": true
    ]

    guard let processed = manager.processParameters(parameters, eventName: name) as? [String: String] else {
      return XCTFail("Processed parameters should be in the expected format")
    }

    XCTAssertNil(
      processed["address"]
    )
    XCTAssertNil(
      processed["period_starts"]
    )
    guard let onDeviceParams = processed["_onDeviceParams"] else {
      return XCTFail("Should have the expected processed on-device parameters")
    }
    XCTAssertTrue(
      onDeviceParams.contains("address")
    )
    XCTAssertTrue(
      onDeviceParams.contains("period_starts")
    )
  }

  func testProcessingParametersWithNonRestrictedData() {
    manager.enable()

    let parameters: [String: Any] = [
      "_valueToSum": 1,
      "_session_id": "12345"
    ]
    processor.stubbedParameters = [
      "_valueToSum": false,
      "_session_id": false
    ]
    guard let processed = manager.processParameters(parameters, eventName: name) else {
      return XCTFail("Processed parameters should be in the expected format")
    }

    XCTAssertNotNil(processed["_valueToSum"])
    XCTAssertNotNil(processed["_session_id"])
    XCTAssertNil(processed["_onDeviceParams"])
  }
}
