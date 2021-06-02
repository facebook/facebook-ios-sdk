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

class FBSDKTimeSpentDataTests: XCTest {

  let applicationName = "someApplication"
  let eventLogger = TestEventLogger()
  lazy var timeSpentData = TimeSpentData(
    eventLogger: eventLogger,
    serverConfigurationProvider: TestServerConfigurationProvider.self
  )

  override func setUp() {
    super.setUp()

    TestServerConfigurationProvider.reset()
  }

  override func tearDown() {
    super.tearDown()

    TestServerConfigurationProvider.reset()
  }

  func testCreatingWithDependencies() {
    XCTAssertEqual(
      timeSpentData.eventLogger as? TestEventLogger,
      eventLogger,
      "Should store the provided event logger"
    )
  }

  func testSetSourceApplication() {
    timeSpentData.setSourceApplication(applicationName, isFromAppLink: true)
    XCTAssertEqual(timeSpentData.sourceApplication, "AppLink(someApplication)")

    timeSpentData.resetSourceApplication()
    XCTAssertEqual(timeSpentData.sourceApplication, "Unclassified")
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
