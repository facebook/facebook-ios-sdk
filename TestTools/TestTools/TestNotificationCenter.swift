/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

import FBSDKCoreKit_Basics

@objcMembers
public final class TestNotificationCenter: NSObject, NotificationDelivering {

  private let stubbedObject = NSObject()

  public struct ObserverEvidence: Equatable {
    let observer: Any?
    let name: Notification.Name?
    let selector: Selector?
    let object: Any?

    public init(
      observer: Any?,
      name: Notification.Name?,
      selector: Selector?,
      object: Any?
    ) {
      self.observer = observer
      self.name = name
      self.selector = selector
      self.object = object
    }

    public static func == (
      lhs: TestNotificationCenter.ObserverEvidence,
      rhs: TestNotificationCenter.ObserverEvidence
    ) -> Bool {
      lhs.observer as AnyObject === rhs.observer as AnyObject &&
        lhs.name == rhs.name &&
        lhs.selector == rhs.selector &&
        lhs.object as AnyObject === rhs.object as AnyObject
    }
  }

  public var capturedRemovedObservers = [Any]()
  public var capturedPostNames = [NSNotification.Name]()
  public var capturedPostObjects = [Any]()
  public var capturedPostUserInfos = [[String: Any]]()
  public var capturedCompletions = [(Notification) -> Void]()

  public var capturedAddObserverInvocations = [ObserverEvidence]()

  // MARK: Delivering

  public func fb_removeObserver(_ observer: Any) {
    capturedRemovedObservers.append(observer)
  }

  public func fb_addObserver(
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

  public func fb_addObserver(
    forName name: NSNotification.Name?,
    object: Any?,
    queue: OperationQueue?,
    using block: @escaping (Notification) -> Void
  ) -> NSObjectProtocol {
    capturedAddObserverInvocations.append(
      .init(
        observer: nil,
        name: name,
        selector: nil,
        object: object
      )
    )
    capturedCompletions.append(block)

    return stubbedObject
  }

  public func clearTestEvidence() {
    capturedRemovedObservers = []
    capturedPostNames = []
    capturedPostObjects = []
    capturedPostUserInfos = []
  }
}
