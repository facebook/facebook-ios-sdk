/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class TimeSpentDataTests: XCTestCase {

  let applicationName = "someApplication"
  let eventLogger = TestEventLogger()
  lazy var timeSpentData = TimeSpentData(
    eventLogger: eventLogger,
    serverConfigurationProvider: TestServerConfigurationProvider()
  )

  func testCreatingWithDependencies() {
    XCTAssertEqual(
      timeSpentData.eventLogger as? TestEventLogger,
      eventLogger,
      "Should store the provided event logger"
    )
  }

  func testSetSourceApplication() {
    timeSpentData.setSourceApplication(applicationName, isFromAppLink: true)
    XCTAssertEqual(timeSpentData.getSourceApplication(), "AppLink(someApplication)")

    timeSpentData.resetSourceApplication()
    XCTAssertEqual(timeSpentData.getSourceApplication(), "Unclassified")
  }

  func testAppEventsParametersForDeactivate() {
    timeSpentData.setSourceApplication(applicationName, isFromAppLink: true)
    let params = timeSpentData.appEventsParametersForDeactivate()
    XCTAssertNotNil(params["_session_id"])
    XCTAssertNotNil(params["fb_mobile_app_interruptions"])
    XCTAssertNotNil(params["fb_mobile_launch_source"])
    XCTAssertNotNil(params["fb_mobile_time_between_sessions"])
  }
}
