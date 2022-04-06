/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

extension AppEvents.Name {
  // MARK: Message Dialog

  static let messengerShareDialogShow = AppEvents.Name("fb_messenger_dialog_share_show")
  static let messengerShareDialogResult = AppEvents.Name("fb_messenger_dialog_share_result")

  // MARK: Send Button

  static let sendButtonImpression = AppEvents.Name("fb_send_button_impression")
  static let sendButtonDidTap = AppEvents.Name("fb_send_button_did_tap")

  // MARK: Share Button

  static let shareButtonImpression = AppEvents.Name("fb_share_button_impression")
  static let shareButtonDidTap = AppEvents.Name("fb_share_button_did_tap")

  // MARK: Share Dialog

  static let shareDialogShow = AppEvents.Name("fb_dialog_share_show")
  static let shareDialogResult = AppEvents.Name("fb_dialog_share_result")
}
