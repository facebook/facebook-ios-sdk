/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import Foundation

/// The common interface for dialogs that initiate sharing.
@objc(FBSDKSharingDialog)
public protocol SharingDialog: Sharing {

  /**
   A boolean value that indicates whether the receiver can initiate a share.

   May return `false` if the appropriate Facebook app is not installed and is required or an access token is
   required but not available.  This method does not validate the content on the receiver, so this can be checked before
   building up the content.

   See `Sharing.validate(error:)`
   @return `true` if the receiver can share, otherwise `false`.
   */
  var canShow: Bool { get }

  /**
   Shows the dialog.
   @return `true` if the receiver was able to begin sharing, otherwise `false`.
   */
  @discardableResult
  func show() -> Bool
}

#endif
