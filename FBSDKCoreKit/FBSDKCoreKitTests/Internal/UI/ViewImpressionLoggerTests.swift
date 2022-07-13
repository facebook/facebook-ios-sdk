/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import XCTest

final class ViewImpressionLoggerTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var graphRequestFactory: TestGraphRequestFactory!
  var logger: TestEventLogger!
  var notificationCenter: TestNotificationCenter!
  // swiftlint:enable implicitly_unwrapped_optional
  let sharedTrackerName = AppEvents.Name("shared")
  lazy var tracker = createImpressionLogger(named: sharedTrackerName)
  let impressionIdentifier = "foo"
  let parameters: [AppEvents.ParameterName: String] = [.init("bar"): "baz"]

  override func setUp() {
    super.setUp()

    graphRequestFactory = TestGraphRequestFactory()
    logger = TestEventLogger()
    notificationCenter = TestNotificationCenter()

    TestAccessTokenWallet.current = SampleAccessTokens.validToken
    _ViewImpressionLogger.setDependencies(
      .init(
        graphRequestFactory: graphRequestFactory,
        eventLogger: logger,
        notificationDeliverer: notificationCenter,
        tokenWallet: TestAccessTokenWallet.self
      )
    )
    tracker = createImpressionLogger(named: sharedTrackerName)
  }

  override func tearDown() {
    graphRequestFactory = nil
    logger = nil
    notificationCenter = nil
    TestAccessTokenWallet.current = nil
    _ViewImpressionLogger.resetDependencies()
    super.tearDown()
  }

  // MARK: - Dependencies

  func testDefaultTypeDependencies() throws {
    _ViewImpressionLogger.resetDependencies()
    let dependencies = try _ViewImpressionLogger.getDependencies()

    XCTAssertTrue(
      dependencies.graphRequestFactory is GraphRequestFactory,
      .defaultDependency("GraphRequestFactory", for: "graph request factory")
    )

    XCTAssertIdentical(
      dependencies.eventLogger as AnyObject,
      AppEvents.shared,
      .customDependency(for: "event logging")
    )

    XCTAssertIdentical(
      dependencies.notificationDeliverer as AnyObject,
      NotificationCenter.default,
      .customDependency(for: "notification delivery")
    )

    XCTAssertIdentical(
      dependencies.tokenWallet as AnyObject,
      AccessToken.self,
      .customDependency(for: "access token")
    )
  }

  func testCustomTypeDependencies() throws {
    let dependencies = try _ViewImpressionLogger.getDependencies()

    XCTAssertIdentical(
      dependencies.graphRequestFactory as AnyObject,
      graphRequestFactory,
      .customDependency(for: "graph request factory")
    )

    XCTAssertIdentical(
      dependencies.eventLogger as AnyObject,
      logger,
      .customDependency(for: "event logging")
    )

    XCTAssertIdentical(
      dependencies.notificationDeliverer as AnyObject,
      notificationCenter,
      .customDependency(for: "notification delivery")
    )

    XCTAssertIdentical(
      dependencies.tokenWallet as AnyObject,
      TestAccessTokenWallet.self,
      .customDependency(for: "access token")
    )
  }

  // MARK: - Notifications

  func testCreatingSetsUpNotificationObserving() {
    XCTAssertTrue(
      notificationCenter.capturedAddObserverInvocations.contains(
        TestNotificationCenter.ObserverEvidence(
          observer: tracker as Any,
          name: UIApplication.didEnterBackgroundNotification,
          selector: #selector(_ViewImpressionLogger.applicationDidEnterBackground),
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
    XCTAssertFalse(tracker.trackedImpressions.isEmpty)

    tracker.applicationDidEnterBackground(Notification(name: .init("foo")))

    XCTAssertTrue(
      tracker.trackedImpressions.isEmpty,
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
      logger.capturedParameters as? [AppEvents.ParameterName: String],
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
      logger.capturedParameters?[.init("__view_impression_identifier__")],
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

  func createImpressionLogger(named name: AppEvents.Name) -> _ViewImpressionLogger {
    _ViewImpressionLogger(eventName: name)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static func defaultDependency(_ dependency: String, for type: String) -> String {
    "The _ViewImpressionLogger type uses \(dependency) as its \(type) dependency by default"
  }

  static func customDependency(for type: String) -> String {
    "The _ViewImpressionLogger type uses a custom \(type) dependency when provided"
  }
}
