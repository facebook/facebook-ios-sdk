/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

struct ProfilePictureViewState: Equatable {
  let profileID: String
  let size: CGSize
  let scale: CGFloat
  let pictureMode: Profile.PictureMode
  let imageShouldFit: Bool
}
