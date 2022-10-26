/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */

@objcMembers
@objc(FBSDKMeasurementEvent)
public final class _MeasurementEvent: NSObject, _AppLinkEventPosting {

  /// Defines keys in the userInfo object for the notification named `measurementEvent`
  private enum Keys {

    /// The string field for the name of the event
    static let name = "event_name"

    /// The dictionary field for the arguments of the event
    static let arguments = "event_args"
  }

  @objc(postNotificationForEventName:args:)
  public func postNotification(eventName: String, arguments: [String: Any]) {

    let notificationCenter = NotificationCenter.default
    let userInfo: [String: Any] = [
      Keys.name: eventName,
      Keys.arguments: arguments,
    ]

    notificationCenter.post(name: .MeasurementEvent, object: self, userInfo: userInfo)
  }
}
