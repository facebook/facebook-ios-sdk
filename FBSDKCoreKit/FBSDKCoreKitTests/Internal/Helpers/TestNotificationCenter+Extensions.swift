/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

import FBSDKCoreKit_Basics

extension TestNotificationCenter: NotificationPosting {

  // MARK: Posting

  public func fb_post(
    name: Notification.Name,
    object: Any?,
    userInfo: [String: Any]? = nil
  ) {
    capturedPostNames.append(name)
    capturedPostObjects.append(object as Any)
    capturedPostUserInfos.append(userInfo ?? [:])
  }
}
