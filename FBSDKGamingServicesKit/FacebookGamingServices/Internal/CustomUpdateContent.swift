// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

public class CustomUpdateContentImage {

  var contextTokenID: String
  var message: String
  var image: UIImage?
  var ctaText: String?
  var payload: String?
  var messageLocalization: [String: String]
  var ctaLocalization: [String: String]

  /**
   Init method for a custom update content with an image

   - Parameters:
    - contextTokenID: The context token id of the game instance in which to send the update
    - message:  The message to be display in the update
    - image: The image to display in the update
    - cta: The text to display in the action button for the update
    - payload: The payload string that will be passed backed when the receiver interacts with the update
    - messageLocalization: A dictionary of any Localization that should be applied to the message
    - ctaLocalization: A dictionary of any Localization that should be applied to the CTA
   */
  public convenience init(
    contextTokenID: String,
    message: String,
    image: UIImage,
    cta: String?,
    payload: String?,
    messageLocalization: [String: String],
    ctaLocalization: [String: String]
  ) {
    self.init(contextTokenID: contextTokenID, message: message)

    self.contextTokenID = contextTokenID
    self.message = message
    self.image = image
    self.ctaText = cta
    self.payload = payload
    self.messageLocalization = messageLocalization
    self.ctaLocalization = ctaLocalization
  }

  /**
    initializer for the required content values to send a custom update request

   - Parameters:
    - contextTokenID: The context token id of the game instance the user triggering the custom update is currently in
    - message: The message to be displayed in the update
    - image: The image to display in the update
    */
  public convenience init(contextTokenID: String, message: String, image: UIImage) {
    self.init(contextTokenID: contextTokenID, message: message)
    self.image = image
  }

  /**
     Private initializer used in the convenience initializers.

   - Parameters:
    - contextTokenID: The context token id of the game instance the user triggering the custom update is currently in
    - message: The message to be displayed in the update
    */
  private init(contextTokenID: String, message: String) {
    self.contextTokenID = contextTokenID
    self.message = message
    self.messageLocalization = [:]
    self.ctaLocalization = [:]
  }
}

public class CustomUpdateContentMedia {

  var contextTokenID: String
  var message: String
  var media: URLMedia?
  var ctaText: String?
  var payload: String?
  var messageLocalization: [String: String]
  var ctaLocalization: [String: String]

  /**
   initializer method for a custom update content with media

   - Parameters:
    - contextTokenID: The context token id of the game instance in which to send the update
    - message:  The message to display in the update
    - media: The media to display with the message
    - cta: The text to display in the action button for the update
    - payload: This is the payload string that will be passed backed when the receiver interacts with the sent message
    - messageLocalization: A dictionary of any Localization that should be applied to the message
    - ctaLocalization: A dictionary of any Localization that should be applied to the CTA
   */
  public convenience init(
    contextTokenID: String,
    message: String,
    media: URLMedia,
    cta: String?,
    payload: String?,
    messageLocalization: [String: String],
    ctaLocalization: [String: String]
  ) {
    self.init(contextTokenID: contextTokenID, message: message)

    self.contextTokenID = contextTokenID
    self.message = message
    self.ctaText = cta
    self.media = media
    self.payload = payload
    self.messageLocalization = messageLocalization
    self.ctaLocalization = ctaLocalization
  }

  /**
    initializer for the required content values to send a custom update request

   - Parameters:
    - contextTokenID: The context token id of the game instance the user triggering the custom update is currently in
    - message: The message to be displayed in the update
    - media: The media to display with the message
    */
  public convenience init(contextTokenID: String, message: String, media: URLMedia) {
    self.init(contextTokenID: contextTokenID, message: message)
    self.media = media
  }

  /**
     Private initializer used in the convenience initializers.

   - Parameters:
    - contextTokenID: The context token id of the game instance the user triggering the custom update is currently in
    - message: The message to be displayed in the update
    */
  private init(contextTokenID: String, message: String) {
    self.contextTokenID = contextTokenID
    self.message = message
    self.messageLocalization = [:]
    self.ctaLocalization = [:]
  }
}
