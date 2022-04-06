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
 The common interface for components that initiate sharing.

 See ShareDialog, MessageDialog
 */
@objc(FBSDKSharing)
public protocol Sharing {

  /// The receiver's delegate or nil if it doesn't have a delegate.
  weak var delegate: SharingDelegate? { get set }

  /// The content to be shared.
  var shareContent: SharingContent? { get set }

  /**
   A boolean value that indicates whether the receiver should fail if it finds an error with the share content.

   If `false`, the sharer will still be displayed without the data that was misconfigured.  For example, an
   invalid `placeID` specified on the `shareContent` would produce a data error.
   */
  var shouldFailOnDataError: Bool { get set }

  /**
   Validates the content on the receiver.

   @throws An error if the content is invalid
   */
  @objc(validateWithError:)
  func validate() throws
}

#endif
