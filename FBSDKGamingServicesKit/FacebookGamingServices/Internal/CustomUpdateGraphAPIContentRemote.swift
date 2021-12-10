/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import UIKit

class CustomUpdateGraphAPIContentRemote: Codable {

  var contextTokenID: String
  var text: CustomUpdateLocalizedText
  var media: CustomUpdateMedia?
  var cta: CustomUpdateLocalizedText?
  var image: Data?
  var data: String?

  init(customUpdateContentMedia: CustomUpdateContentMedia) throws {
    guard let currentContextID = GamingContext.current?.identifier else {
      throw CustomUpdateContentError.notInGameContext
    }

    guard let message = CustomUpdateLocalizedText(
      defaultString: customUpdateContentMedia.message,
      localizations: customUpdateContentMedia.messageLocalization
    ) else {
      throw CustomUpdateContentError.invalidMessage
    }

    guard
      let media = customUpdateContentMedia.media,
      let customUpdateMedia = CustomUpdateMedia(media: media)
    else {
      throw CustomUpdateContentError.invalidMedia
    }

    self.contextTokenID = currentContextID
    self.text = message
    self.cta = CustomUpdateLocalizedText(
      defaultString: customUpdateContentMedia.ctaText ?? "",
      localizations: customUpdateContentMedia.ctaLocalization
    )
    self.data = customUpdateContentMedia.payload
    self.media = customUpdateMedia
  }

  init(customUpdateContentImage: CustomUpdateContentImage) throws {
    guard let currentContextID = GamingContext.current?.identifier else {
      throw CustomUpdateContentError.notInGameContext
    }

    guard let message = CustomUpdateLocalizedText(
      defaultString: customUpdateContentImage.message,
      localizations: customUpdateContentImage.messageLocalization
    ) else {
      throw CustomUpdateContentError.invalidMessage
    }

    guard
      let imageData = customUpdateContentImage.image?.pngData()
    else {
      throw CustomUpdateContentError.invalidImage
    }

    self.contextTokenID = currentContextID
    self.text = message
    self.cta = CustomUpdateLocalizedText(
      defaultString: customUpdateContentImage.ctaText ?? "",
      localizations: customUpdateContentImage.ctaLocalization
    )
    self.data = customUpdateContentImage.payload
    self.image = imageData
  }

  enum CodingKeys: String, CodingKey {
    case contextTokenID = "context_token_id"
    case text
    case cta
    case image
    case media
    case data
  }
}
