/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

public class CustomUpdateContentMedia {

  var message: String
  var media: URLMedia?
  var ctaText: String?
  var payload: String?
  var messageLocalization: [String: String]
  var ctaLocalization: [String: String]

  /**
   initializer method for a custom update content with media

   - Parameters:
    - message:  The message to display in the update
    - media: The media to display with the message
    - cta: The text to display in the action button for the update
    - payload: This is the payload string that will be passed backed when the receiver interacts with the sent message
    - messageLocalization: A dictionary of any Localization that should be applied to the message
    - ctaLocalization: A dictionary of any Localization that should be applied to the CTA
   */
  public init(
    message: String,
    media: URLMedia,
    cta: String? = nil,
    payload: String? = nil,
    messageLocalization: [String: String] = [:],
    ctaLocalization: [String: String] = [:]
  ) {
    self.message = message
    self.ctaText = cta
    self.media = media
    self.payload = payload
    self.messageLocalization = messageLocalization
    self.ctaLocalization = ctaLocalization
  }
}
