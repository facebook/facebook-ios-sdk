/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import FBSDKCoreKit_Basics
import Foundation

#if !os(tvOS)

final class GameRequestFrictionlessRecipientCache {
  private var recipientIDs = Set<String>()

  init() {
    _ = NotificationCenter.default.addObserver(
      forName: .AccessTokenDidChange,
      object: nil,
      queue: nil
    ) { [weak self] notification in
      self?.accessTokenDidChange(notification: notification)
    }

    updateCache()
  }

  func recipientsAreFrictionless(_ potentialRecipients: Any?) -> Bool {
    guard let typeErasedRecipients = potentialRecipients else { return false }

    let recipients: [String]
    if let recipientsArray = typeErasedRecipients as? [String] {
      recipients = recipientsArray
    } else if let recipientsString = typeErasedRecipients as? String {
      recipients = recipientsString.components(separatedBy: ",")
    } else {
      return false
    }

    return Set(recipients).isSubset(of: recipientIDs)
  }

  func update(results: [String: Any]) {
    if let value = results["updated_frictionless"],
       TypeUtility.boolValue(value) {
      updateCache()
    }
  }

  private func accessTokenDidChange(notification: Notification) {
    let didChangeUserID = (notification.userInfo?[AccessTokenDidChangeUserIDKey] as? Bool) ?? false
    guard didChangeUserID else { return }

    recipientIDs = []
    updateCache()
  }

  private func updateCache() {
    guard AccessToken.current != nil else {
      recipientIDs = []
      return
    }

    let request = GraphRequest(
      graphPath: "me/apprequestformerrecipients",
      parameters: ["fields": ""],
      flags: [.doNotInvalidateTokenOnError, .disableErrorRecovery]
    )
    request.start { _, result, error in
      guard error == nil else { return }

      let values = result as? [String: Any]
      let items = values?["data"] as? [String: Any]
      let recipients = items?["recipient_id"] as? [String]
      self.recipientIDs = Set(recipients ?? [])
    }
  }
}

#endif
