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
@objc(FBSDKLogo)
public final class _FBLogo: FBIcon {
  public override func path(with size: CGSize) -> CGPath? {
    let originalCanvasWidth: CGFloat = 1366
    let originalCanvasHeight: CGFloat = 1366

    let transformValue = CGAffineTransform(
      scaleX: size.width / originalCanvasWidth,
      y: size.height / originalCanvasHeight
    )

    let path = UIBezierPath()
    path.move(to: CGPoint(x: 1365.33, y: 682.67))
    path.addCurve(
      to: CGPoint(x: 682.67, y: -0),
      controlPoint1: CGPoint(x: 1365.33, y: 305.64),
      controlPoint2: CGPoint(x: 1059.69, y: -0)
    )
    path.addCurve(
      to: CGPoint(x: 0, y: 682.67),
      controlPoint1: CGPoint(x: 305.64, y: -0),
      controlPoint2: CGPoint(x: 0, y: 305.64)
    )
    path.addCurve(
      to: CGPoint(x: 576, y: 1357.04),
      controlPoint1: CGPoint(x: 0, y: 1023.41),
      controlPoint2: CGPoint(x: 249.64, y: 1305.83)
    )

    path.addLine(to: CGPoint(x: 576, y: 880))
    path.addLine(to: CGPoint(x: 402.67, y: 880))
    path.addLine(to: CGPoint(x: 402.67, y: 682.67))
    path.addLine(to: CGPoint(x: 576, y: 682.67))
    path.addLine(to: CGPoint(x: 576, y: 532.27))

    path.addCurve(
      to: CGPoint(x: 833.85, y: 266.67),
      controlPoint1: CGPoint(x: 576, y: 361.17),
      controlPoint2: CGPoint(x: 677.92, y: 266.67)
    )
    path.addCurve(
      to: CGPoint(x: 986.67, y: 280),
      controlPoint1: CGPoint(x: 908.54, y: 266.67),
      controlPoint2: CGPoint(x: 986.67, y: 280)
    )

    path.addLine(to: CGPoint(x: 986.67, y: 448))
    path.addLine(to: CGPoint(x: 900.58, y: 448))

    path.addCurve(
      to: CGPoint(x: 789.33, y: 554.61),
      controlPoint1: CGPoint(x: 815.78, y: 448),
      controlPoint2: CGPoint(x: 789.33, y: 500.62)
    )

    path.addLine(to: CGPoint(x: 789.33, y: 682.67))
    path.addLine(to: CGPoint(x: 978.67, y: 682.67))
    path.addLine(to: CGPoint(x: 948.4, y: 880))
    path.addLine(to: CGPoint(x: 789.33, y: 880))
    path.addLine(to: CGPoint(x: 789.33, y: 1357.04))

    path.addCurve(
      to: CGPoint(x: 1365.33, y: 682.67),
      controlPoint1: CGPoint(x: 1115.69, y: 1305.83),
      controlPoint2: CGPoint(x: 1365.33, y: 1023.41)
    )

    path.close()
    path.apply(transformValue)
    return path.cgPath
  }
}
