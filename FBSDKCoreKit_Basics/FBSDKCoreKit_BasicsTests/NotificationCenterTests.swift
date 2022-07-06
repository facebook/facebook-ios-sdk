/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics
import Foundation
import XCTest

final class NotificationCenterTests: XCTestCase {
  // swiftlint:disable implicitly_unwrapped_optional
  var notificationCenter: NotificationCenter!
  var notificationObject: AnyObject!
  var observer: Any!
  // swiftlint:enable implicitly_unwrapped_optional

  let userInfo = ["key": "value"]
  var observedNotification: Notification?

  override func setUp() {
    super.setUp()

    notificationCenter = NotificationCenter.default
    notificationObject = NSObject()
  }

  override func tearDown() {
    removeObserver()

    notificationCenter = nil
    notificationObject = nil
    observer = nil

    super.tearDown()
  }

  func testAddingObserver() throws {
    notificationCenter.fb_addObserver(
      self,
      selector: #selector(handleNotification(_:)),
      name: .sample,
      object: notificationObject
    )

    postNotification()
    try validateNotification(message: .addObserver)
  }

  func testAddingObserverWithTrailingClosure() throws {
    notificationCenter.fb_addObserver(forName: .sample, object: notificationObject, queue: nil) { notification in
      self.observedNotification = notification
    }

    postNotification()
    try validateNotification(message: .addObserver)
  }

  func testRemovingObserver() {
    addObserver()

    notificationCenter.fb_removeObserver(observer!) // swiftlint:disable:this force_unwrapping

    postNotification()
    XCTAssertNil(observedNotification, .removeObserver)
  }

  // MARK: - Helpers

  @objc
  private func handleNotification(_ notification: Notification) {
    observedNotification = notification
  }

  private func addObserver() {
    observer = notificationCenter.addObserver(
      forName: .sample,
      object: notificationObject,
      queue: nil
    ) { [self] notification in
      observedNotification = notification
    }
  }

  private func removeObserver() {
    guard let observer = observer else { return }

    notificationCenter.removeObserver(observer)
  }

  private func postNotification() {
    notificationCenter.post(
      name: .sample,
      object: notificationObject,
      userInfo: userInfo
    )
  }

  private func validateNotification(message: String, file: StaticString = #file, line: UInt = #line) throws {
    let notification = try XCTUnwrap(observedNotification, message, file: file, line: line)
    XCTAssertEqual(notification.name, .sample, message, file: file, line: line)
    XCTAssertIdentical(notification.object as AnyObject, notificationObject, message, file: file, line: line)
    XCTAssertEqual(notification.userInfo as? [String: String], userInfo, message, file: file, line: line)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let addObserver = "A notification center can add a notification observer through an internal abstraction"
  static let removeObserver = "A notification center can remove a notification observer through an internal abstraction"
}

// MARK: - Test Values

fileprivate extension Notification.Name {
  static let sample = Self("sample-notification")
}
