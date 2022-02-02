/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit

@objcMembers
@objc(FBSDKMessengerIcon)
final class MessengerIcon: Icon {

  override func path(with size: CGSize) -> Unmanaged<CGPath>? {
    let scale = CGAffineTransform(scaleX: size.width / 61.0, y: size.height / 61.0)
    let path = CGMutablePath()

    path.move(to: .init(x: 30.001, y: 0.962), transform: scale)
    path.addCurve(
      to: .init(x: 0.014, y: 28.882),
      control1: .init(x: 13.439, y: 0.962),
      control2: .init(x: 0.014, y: 13.462),
      transform: scale
    )
    path.addCurve(
      to: .init(x: 10.046, y: 49.549),
      control1: .init(x: 0.014, y: 37.165),
      control2: .init(x: 3.892, y: 44.516),
      transform: scale
    )
    path.addLine(to: .init(x: 10.046, y: 61.176), transform: scale)
    path.addLine(to: .init(x: 19.351, y: 54.722), transform: scale)
    path.addCurve(
      to: .init(x: 30.002, y: 56.502),
      control1: .init(x: 22.662, y: 55.870),
      control2: .init(x: 26.250, y: 56.502),
      transform: scale
    )
    path.addCurve(
      to: .init(x: 59.990, y: 28.882),
      control1: .init(x: 46.565, y: 56.502),
      control2: .init(x: 59.990, y: 44.301),
      transform: scale
    )
    path.addCurve(
      to: .init(x: 30.001, y: 0.962),
      control1: .init(x: 59.989, y: 13.462),
      control2: .init(x: 46.564, y: 0.962),
      transform: scale
    )
    path.closeSubpath()

    path.move(to: .init(x: 33.159, y: 37.473), transform: scale)
    path.addLine(to: .init(x: 25.403, y: 29.484), transform: scale)
    path.addLine(to: .init(x: 10.467, y: 37.674), transform: scale)
    path.addLine(to: .init(x: 26.843, y: 20.445), transform: scale)
    path.addLine(to: .init(x: 34.599, y: 28.433), transform: scale)
    path.addLine(to: .init(x: 49.535, y: 20.244), transform: scale)
    path.addLine(to: .init(x: 33.159, y: 37.473), transform: scale)
    path.closeSubpath()

    return Unmanaged.passRetained(path).autorelease()
  }
}

#endif
