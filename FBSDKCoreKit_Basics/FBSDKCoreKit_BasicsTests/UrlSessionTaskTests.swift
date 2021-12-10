/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics
import TestTools
import XCTest

class UrlSessionTaskTests: XCTestCase {

  let dataTask = TestSessionDataTask()
  let provider = TestSessionProvider()
  lazy var task = UrlSessionTask(
    request: SampleURLRequest.valid,
    fromSession: provider,
    completionHandler: nil
  )! // swiftlint:disable:this force_unwrapping

  override func setUp() {
    super.setUp()

    provider.stubbedDataTask = dataTask
  }

  func testStarting() {
    task.start()

    XCTAssertEqual(
      dataTask.resumeCallCount,
      1,
      "Starting a session task should resume the underlying data task"
    )
  }

  func testStopping() {
    task.cancel()

    XCTAssertEqual(
      dataTask.cancelCallCount,
      1,
      "Cancelling a session task should cancel the underlying data task"
    )
  }

  func testState() {
    dataTask.stubbedState = .running
    XCTAssertEqual(
      task.state,
      .running,
      "Should return the state of the underlying data task"
    )
  }
}
