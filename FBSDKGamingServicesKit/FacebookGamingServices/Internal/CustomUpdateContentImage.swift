/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

public class CustomUpdateContentImage {

  var message: String
  var image: UIImage?
  var ctaText: String?
  var payload: String?
  var messageLocalization: [String: String]
  var ctaLocalization: [String: String]

  /**
   Init method for a custom update content with an image

   - Parameters:
    - message:  The message to be display in the update
    - image: The image to display in the update
    - cta: The text to display in the action button for the update
    - payload: The payload string that will be passed backed when the receiver interacts with the update
    - messageLocalization: A dictionary of any Localization that should be applied to the message
    - ctaLocalization: A dictionary of any Localization that should be applied to the CTA
   */
  public init(
    message: String,
    image: UIImage,
    cta: String? = nil,
    payload: String? = nil,
    messageLocalization: [String: String] = [:],
    ctaLocalization: [String: String] = [:]
  ) {
    self.message = message
    self.image = image
    self.ctaText = cta
    self.payload = payload
    self.messageLocalization = messageLocalization
    self.ctaLocalization = ctaLocalization
  }
}
