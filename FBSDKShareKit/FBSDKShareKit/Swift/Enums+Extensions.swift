/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 ShareDialog.Mode CustomStringConvertible
 */
@available(tvOS, unavailable)
extension ShareDialog.Mode: CustomStringConvertible {
  /// The string description
  public var description: String {
    __NSStringFromFBSDKShareDialogMode(self)
  }
}

/**
 AppGroupPrivacy CustomStringConvertible
 */
@available(tvOS, unavailable)
extension AppGroupPrivacy: CustomStringConvertible {
  /// The string description
  public var description: String {
    __NSStringFromFBSDKAppGroupPrivacy(self)
  }
}
