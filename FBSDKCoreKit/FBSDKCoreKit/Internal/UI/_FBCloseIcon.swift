/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */

@objcMembers
@objc(FBSDKCloseIcon)
public final class _FBCloseIcon: NSObject {

  public func image(size: CGSize) -> UIImage? {
    image(size: size, primaryColor: .white, secondaryColor: .black, scale: UIScreen.main.scale)
  }

  func image(size: CGSize, primaryColor: UIColor, secondaryColor: UIColor, scale: CGFloat) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    guard let context = UIGraphicsGetCurrentContext() else { return nil }

    let iconSize = min(size.width, size.height)

    var rect = CGRect(
      x: (size.width - iconSize) / 2,
      y: (size.height - iconSize) / 2,
      width: iconSize,
      height: iconSize
    )

    let step = iconSize / 12

    // shadow
    rect = rect.insetBy(dx: step, dy: step).integral
    let colors = [
      UIColor(white: 0, alpha: 0.7).cgColor,
      UIColor(white: 0, alpha: 0.3).cgColor,
      UIColor(white: 0, alpha: 0.1).cgColor,
      UIColor(white: 0, alpha: 0.0).cgColor,
    ]

    let locations: [CGFloat] = [
      0.70,
      0.80,
      0.90,
      1.0,
    ]
    let colorSpace = CGColorSpaceCreateDeviceGray()
    guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) else {
      return nil
    }
    let center = CGPoint(x: rect.midX - step / 6, y: rect.midY + step / 4)
    context.drawRadialGradient(
      gradient,
      startCenter: center,
      startRadius: 0,
      endCenter: center,
      endRadius: (rect.width - step / 2) / 2,
      options: []
    )

    // outer circle
    rect = rect.insetBy(dx: step, dy: step).integral
    primaryColor.setFill()
    context.fillEllipse(in: rect)

    // inner circle
    rect = rect.insetBy(dx: step, dy: step).integral
    secondaryColor.setFill()
    context.fillEllipse(in: rect)

    // cross
    rect = rect.insetBy(dx: step, dy: step).integral
    let lineWidth = step * 5 / 4
    rect.origin.y = rect.midY - lineWidth / 2
    rect.size.height = lineWidth
    primaryColor.setFill()

    context.translateBy(x: size.width / 2, y: size.height / 2)
    context.rotate(by: .pi / 4)
    context.translateBy(x: -size.width / 2, y: -size.height / 2)
    context.fill(rect)
    context.translateBy(x: size.width / 2, y: size.height / 2)
    context.rotate(by: .pi / 2)
    context.translateBy(x: -size.width / 2, y: -size.height / 2)
    context.fill(rect)

    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
  }
}

#endif
