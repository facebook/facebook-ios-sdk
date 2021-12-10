/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
class TestNotificationCenter: NSObject, NotificationObserving, NotificationPosting {

  struct ObserverEvidence: Equatable {
    let observer: Any
    let name: Notification.Name?
    let selector: Selector
    let object: Any?

    static func == (
      lhs: TestNotificationCenter.ObserverEvidence,
      rhs: TestNotificationCenter.ObserverEvidence
    ) -> Bool {
      lhs.observer as AnyObject === rhs.observer as AnyObject &&
        lhs.name == rhs.name &&
        lhs.selector == rhs.selector &&
        lhs.object as AnyObject === rhs.object as AnyObject
    }
  }

  var capturedRemovedObservers = [Any]()
  var capturedPostNames = [NSNotification.Name]()
  var capturedPostObjects = [Any]()
  var capturedPostUserInfos = [[String: Any]]()

  var capturedAddObserverInvocations = [ObserverEvidence]()

  // MARK: Posting

  func post(
    name: Notification.Name,
    object: Any?,
    userInfo: [String: Any]? = nil
  ) {
    self.capturedPostNames.append(name)
    self.capturedPostObjects.append(object as Any)
    self.capturedPostUserInfos.append(userInfo ?? [:])
  }

  // MARK: Observing
  func removeObserver(_ observer: Any) {
    capturedRemovedObservers.append(observer)
  }

  func addObserver(
    _ observer: Any,
    selector: Selector,
    name: Notification.Name?,
    object: Any?
  ) {
    capturedAddObserverInvocations.append(
      ObserverEvidence(
        observer: observer,
        name: name,
        selector: selector,
        object: object
      )
    )
  }

  func clearTestEvidence() {
    capturedRemovedObservers = []
    capturedPostNames = []
    capturedPostObjects = []
    capturedPostUserInfos = []
  }
}
