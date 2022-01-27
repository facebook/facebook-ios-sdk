/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

#if !os(tvOS)

/// Filter for who can be displayed in the multi-friend selector.
@objc(FBSDKGameRequestFilter)
public enum GameRequestFilter: UInt {
  /// No filter, all friends can be displayed.
  case none

  /// Friends using the app can be displayed.
  case appUsers

  /// Friends not using the app can be displayed.
  case appNonUsers

  /// All friends can be displayed if FB app is installed.
  case everybody
}

#endif
