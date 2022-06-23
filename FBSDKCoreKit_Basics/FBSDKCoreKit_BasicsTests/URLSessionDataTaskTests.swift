/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class URLSessionDataTaskTests: XCTestCase {

  // swiftlint:disable:next implicitly_unwrapped_optional
  var task: URLSessionDataTask!

  override func setUp() {
    super.setUp()
    task = URLSession.shared.dataTask(with: .sample)
  }

  override func tearDown() {
    task = nil
    super.tearDown()
  }

  func testState() {
    XCTAssertEqual(task.fb_state, .suspended, .hasState)
  }

  func testResume() {
    task.fb_resume()
    XCTAssertEqual(task.state, .running, .resume)
  }

  func testCancel() {
    task.fb_cancel()
    XCTAssertEqual(task.state, .canceling, .cancel)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let hasState = "A data task has a state property through an internal abstraction"
  static let resume = "A data task can be resumed through an internal abstraction"
  static let cancel = "A data task can be cancelled through an internal abstraction"
}

// MARK: - Test Values

fileprivate extension URL {
  // swiftlint:disable:next force_unwrapping
  static let sample = URL(string: "https://facebook.com")!
}
