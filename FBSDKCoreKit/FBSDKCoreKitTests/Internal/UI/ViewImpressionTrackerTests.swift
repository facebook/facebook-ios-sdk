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

class ViewImpressionTrackerTests: XCTestCase {

  var tracker: ViewImpressionTracker! // swiftlint:disable:this implicitly_unwrapped_optional
  let graphRequestFactory = TestGraphRequestFactory()
  let logger = TestEventLogger()
  let notificationCenter = TestNotificationCenter()
  let sharedTrackerName = "shared"
  let impressionIdentifier = "foo"
  let parameters = ["bar": "baz"]

  override func setUp() {
    super.setUp()

    ViewImpressionTracker.reset()
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken

    tracker = createImpressionTracker(named: sharedTrackerName)
  }

  override class func tearDown() {
    super.tearDown()

    ViewImpressionTracker.reset()
  }

  // MARK: - Dependencies

  func testCreatingWithDependencies() {
    XCTAssertTrue(
      tracker.graphRequestFactory === graphRequestFactory,
      "Should be able to create with a graph request provider"
    )
    XCTAssertEqual(
      tracker.eventLogger as? TestEventLogger,
      logger,
      "Should be able to create with an event logger"
    )
    XCTAssertEqual(
      tracker.notificationObserver as? TestNotificationCenter,
      notificationCenter,
      "Should be able to create with a notification observer"
    )
    XCTAssertTrue(
      tracker.tokenWallet is TestAccessTokenWallet.Type,
      "Should be able to create with a token wallet type"
    )
  }

  // MARK: - Notifications

  func testCreatingSetsUpNotificationObserving() {
    XCTAssertTrue(
      notificationCenter.capturedAddObserverInvocations.contains(
        TestNotificationCenter.ObserverEvidence(
          observer: tracker as Any,
          name: UIApplication.didEnterBackgroundNotification,
          selector: #selector(ViewImpressionTracker._applicationDidEnterBackgroundNotification(_:)),
          object: nil
        )
      ),
      "Should start observing application backgrounding upon initialization"
    )
  }

  func testBackgroundingNotificationAction() {
    tracker.logImpression(
      withIdentifier: impressionIdentifier,
      parameters: parameters
    )
    XCTAssertFalse(tracker.trackedImpressions().isEmpty)

    tracker._applicationDidEnterBackgroundNotification(Notification(name: .init("foo")))

    XCTAssertTrue(
      tracker.trackedImpressions().isEmpty,
      "Backgrounding the app should clear any tracked impressions"
    )
  }

  // MARK: - Impression Logging

  func testLoggingSingleImpression() {
    tracker.logImpression(
      withIdentifier: impressionIdentifier,
      parameters: parameters
    )

    XCTAssertEqual(
      logger.capturedEventName,
      sharedTrackerName,
      "Should log an impression with the event name"
    )
    XCTAssertEqual(
      logger.capturedParameters as? [String: String],
      parameters,
      "Should log an impression with the expected parameters"
    )
    XCTAssertTrue(
      logger.capturedIsImplicitlyLogged,
      "Impressions should be implicitly logged"
    )
    XCTAssertEqual(
      logger.capturedAccessToken,
      SampleAccessTokens.validToken,
      "Should log an impression with the expected access token"
    )
  }

  func testLoggingIdenticalImpressions() {
    tracker.logImpression(
      withIdentifier: impressionIdentifier,
      parameters: parameters
    )

    logger.capturedEventName = nil

    tracker.logImpression(
      withIdentifier: impressionIdentifier,
      parameters: parameters
    )

    XCTAssertNil(
      logger.capturedEventName,
      "Should not log the same impression more than once per tracker instance"
    )
  }

  func testLoggingIdenticalImpressionsFromDifferentTrackers() {
    tracker.logImpression(
      withIdentifier: impressionIdentifier,
      parameters: parameters
    )

    logger.capturedEventName = nil
    tracker = createImpressionTracker(named: name)

    tracker.logImpression(
      withIdentifier: impressionIdentifier,
      parameters: parameters
    )

    XCTAssertEqual(
      logger.capturedEventName,
      name,
      "Should log an impression from a new tracker even if the impression is not valid"
    )
    XCTAssertNil(
      logger.capturedParameters["__view_impression_identifier__"],
      "Should not log the same impression twice even if the trackers are different"
    )
  }

  func testLoggingDifferentImpressionsFromSameTracker() {
    tracker.logImpression(
      withIdentifier: impressionIdentifier,
      parameters: parameters
    )

    logger.capturedEventName = nil

    tracker.logImpression(
      withIdentifier: name,
      parameters: parameters
    )

    XCTAssertEqual(
      logger.capturedEventName,
      sharedTrackerName,
      "Should log different impressions using the same tracker"
    )
  }

  func testLoggingDifferentImpressionsFromDifferentTrackers() {
    tracker.logImpression(
      withIdentifier: impressionIdentifier,
      parameters: parameters
    )

    logger.capturedEventName = nil
    tracker = createImpressionTracker(named: name)

    tracker.logImpression(
      withIdentifier: name,
      parameters: parameters
    )

    XCTAssertEqual(
      logger.capturedEventName,
      name,
      "Should be able to log different impressions using different trackers"
    )
  }

  // MARK: - Helpers

  func createImpressionTracker(named name: String) -> ViewImpressionTracker {
    ViewImpressionTracker(
      eventName: name,
      graphRequestFactory: graphRequestFactory,
      eventLogger: logger,
      notificationObserver: notificationCenter,
      tokenWallet: TestAccessTokenWallet.self
    )
  }
}
