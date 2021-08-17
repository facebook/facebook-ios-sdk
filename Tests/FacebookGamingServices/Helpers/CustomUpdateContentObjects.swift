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

import FacebookGamingServices
import Foundation
import UIKit

@available(iOS 13.0, *)
enum CustomUpdateContentObjects {

  // swiftlint:disable force_unwrapping
  static var validID = "12345"
  static var validMessage = "Hello"
  static var gifMedia = FacebookGIF(withUrl: URL(string: "www.test.com")!)
  static var validImage = UIImage(
    named: "customColorSilhouette",
    in: Bundle(for: CustomUpdateGraphAPIContentRemoteTests.self),
    with: nil)!
  static let imageContentInvalidContextID = {
    return CustomUpdateContentImage(
      contextTokenID: "",
      message: validMessage,
      image: validImage)
  }

  static let imageContentInvalidMessage = {
    return CustomUpdateContentImage(
      contextTokenID: validID,
      message: "",
      image: validImage)
  }

  static let imageContentInvalidImage = {
    return CustomUpdateContentImage(
      contextTokenID: validID,
      message: validMessage,
      image: UIImage()
    )
  }

  static let imageContentValid = {
    return CustomUpdateContentImage(
      contextTokenID: validID,
      message: validMessage,
      image: validImage)
  }

  static let mediaContentInvalidContextID = {
    return CustomUpdateContentMedia(
      contextTokenID: "",
      message: validMessage,
      media: gifMedia)
  }

  static let mediaContentInvalidMessage = {
    return CustomUpdateContentMedia(
      contextTokenID: validID,
      message: "",
      media: gifMedia)
  }

  static let mediaContentInvalidMedia = {
    return CustomUpdateContentMedia(
      contextTokenID: validID,
      message: validMessage,
      media: gifMedia)
  }

  static let mediaContentValid = {
    return CustomUpdateContentMedia(
      contextTokenID: validID,
      message: validMessage,
      media: gifMedia)
  }

}
