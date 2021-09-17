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
