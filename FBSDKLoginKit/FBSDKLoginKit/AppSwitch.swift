/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/// The app switch behavior preference to use for a login attempt.
/// App switch allows users to switch to the Facebook app for authentication if installed.
@objc(FBSDKAppSwitch)
public enum AppSwitch: UInt {
  /// Do not use app switch. Use browser-based login (Safari View Controller).
  case disabled

  /// Use app switch if the Facebook app is installed.
  /// This allows users to switch to the Facebook app for authentication. This is the default.
  case enabled
}
