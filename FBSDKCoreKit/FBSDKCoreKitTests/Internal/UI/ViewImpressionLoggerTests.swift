/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

class ViewImpressionLoggerTests: XCTestCase {

  let graphRequestFactory = TestGraphRequestFactory()
  let logger = TestEventLogger()
  let notificationCenter = TestNotificationCenter()
  let sharedTrackerName = AppEvents.Name("shared")
  lazy var tracker = createImpressionLogger(named: sharedTrackerName)
  let impressionIdentifier = "foo"
  let parameters = ["bar": "baz"]

  override func setUp() {
    super.setUp()

    ViewImpressionLogger.reset()
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken
    tracker = createImpressionLogger(named: sharedTrackerName)
  }

  override class func tearDown() {
    super.tearDown()

    ViewImpressionLogger.reset()
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
          selector: #selector(ViewImpressionLogger._applicationDidEnterBackgroundNotification(_:)),
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
    tracker = createImpressionLogger(named: AppEvents.Name(name))

    tracker.logImpression(
      withIdentifier: impressionIdentifier,
      parameters: parameters
    )

    XCTAssertEqual(
      logger.capturedEventName,
      AppEvents.Name(name),
      "Should log an impression from a new tracker even if the impression is not valid"
    )
    XCTAssertNil(
      logger.capturedParameters?["__view_impression_identifier__"],
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
    tracker = createImpressionLogger(named: AppEvents.Name(name))

    tracker.logImpression(
      withIdentifier: name,
      parameters: parameters
    )

    XCTAssertEqual(
      logger.capturedEventName,
      AppEvents.Name(name),
      "Should be able to log different impressions using different trackers"
    )
  }

  // MARK: - Helpers

  func createImpressionLogger(named name: AppEvents.Name) -> ViewImpressionLogger {
    ViewImpressionLogger(
      eventName: name,
      graphRequestFactory: graphRequestFactory,
      eventLogger: logger,
      notificationObserver: notificationCenter,
      tokenWallet: TestAccessTokenWallet.self
    )
  }
}
