/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics
import TestTools
import XCTest

final class FBSDKURLSessionTests: XCTestCase {
  final class TestURLSessionDataDelegate: NSObject, URLSessionDataDelegate {}

  let delegate = TestURLSessionDataDelegate()
  // swiftlint:disable:next implicitly_unwrapped_optional
  var session: FBSDKURLSession!

  override func setUp() {
    super.setUp()

    session = FBSDKURLSession(
      delegate: delegate,
      delegateQueue: OperationQueue()
    )
  }

  override func tearDown() {
    session = nil

    super.tearDown()
  }

  func testDefaultSession() {
    XCTAssertNil(session.session, "Should not have an underlying session by default")
  }

  func testExecutingURLRequestWithoutSession() {
    session.execute(SampleURLRequest.valid) { _, _, _ in }

    XCTAssertNotNil(session.session, "Should create a session when needed")
    XCTAssertIdentical(
      session.delegate,
      delegate,
      "Should create the session using the provided delegate"
    )
  }

  func testExecutingURLRequestWithSession() {
    session.execute(SampleURLRequest.valid) { _, _, _ in }

    let createdSession = session.session

    session.execute(SampleURLRequest.valid) { _, _, _ in }

    XCTAssertIdentical(
      createdSession,
      session.session,
      "Should not create a new session when one exists"
    )
  }

  func testInvalidatingSession() {
    session.execute(SampleURLRequest.valid) { _, _, _ in }
    XCTAssertNotNil(session.session)

    session.invalidateAndCancel()

    XCTAssertNil(
      session.session,
      "Invalidating should clear the underlying session"
    )
  }
}
