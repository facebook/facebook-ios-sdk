/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics
import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(_FBSDKAccessTokenExpirer)
public final class _AccessTokenExpirer: NSObject, _AccessTokenExpiring {
  let notificationCenter: _NotificationPosting & NotificationDelivering
  private var timer: Timer?

  public init(notificationCenter: _NotificationPosting & NotificationDelivering) {
    self.notificationCenter = notificationCenter
    super.init()
    notificationCenter.fb_addObserver(
      self,
      selector: #selector(checkAccessTokenExpirationDate),
      name: .AccessTokenDidChange,
      object: nil
    )
    notificationCenter.fb_addObserver(
      self,
      selector: #selector(checkAccessTokenExpirationDate),
      name: .FBSDKApplicationDidBecomeActive,
      object: nil
    )
    checkAccessTokenExpirationDate()
  }

  deinit {
    timer?.invalidate()
    timer = nil
  }

  func checkAccessTokenExpirationDate() {
    timer?.invalidate()
    timer = nil

    guard let accessToken = AccessToken.current,
          !accessToken.isExpired
    else {
      return
    }

    timer = Timer(
      timeInterval: accessToken.expirationDate.timeIntervalSinceNow,
      target: self,
      selector: #selector(timerDidFire),
      userInfo: nil,
      repeats: false
    )
  }

  func timerDidFire() {
    let accessToken = AccessToken.current
    let userInfo: [String: Any] = [
      AccessTokenChangeNewKey: accessToken as Any,
      AccessTokenChangeOldKey: accessToken as Any,
      AccessTokenDidExpireKey: true,
    ]
    notificationCenter.fb_post(
      name: .AccessTokenDidChange,
      object: AccessToken.self,
      userInfo: userInfo
    )
  }
}
