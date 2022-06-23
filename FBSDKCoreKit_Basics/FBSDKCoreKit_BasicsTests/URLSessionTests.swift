/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics
import XCTest

final class URLSessionTests: XCTestCase {

  // swiftlint:disable:next implicitly_unwrapped_optional
  var session: URLSession!

  override func setUp() {
    super.setUp()
    session = URLSession.shared
  }

  override func tearDown() {
    session = nil
    super.tearDown()
  }

  func testCreatingDataTask() throws {
    let task = try XCTUnwrap(session.fb_dataTask(with: .sample) { _, _, _ in } as? URLSessionTask)
    XCTAssertEqual(task.state, .suspended, .createsDataTasks)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let createsDataTasks = "A URL session creates a data task through an internal abstraction"
}

// MARK: - Test Values

fileprivate extension URLRequest {
  // swiftlint:disable:next force_unwrapping
  static let sample = URLRequest(url: URL(string: "https://facebook.com")!)
}
