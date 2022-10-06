/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBSDKIcon)
open class FBIcon: NSObject {

  open func path(with size: CGSize) -> CGPath? { nil }

  public func image(size: CGSize) -> UIImage? {
    image(size: size, scale: UIScreen.main.scale, color: UIColor.white)
  }

  func image(size: CGSize, scale: CGFloat) -> UIImage? {
    image(size: size, scale: scale, color: UIColor.white)
  }

  public func image(size: CGSize, color: UIColor) -> UIImage? {
    image(size: size, scale: UIScreen.main.scale, color: color)
  }

  public func image(size: CGSize, scale: CGFloat, color: UIColor) -> UIImage? {
    guard
      size.width != 0,
      size.height != 0
    else {
      return nil
    }

    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    guard
      let context = UIGraphicsGetCurrentContext(),
      let path = path(with: size)
    else { return nil }

    context.addPath(path)
    context.setFillColor(color.cgColor)
    context.fillPath()
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
  }
}
