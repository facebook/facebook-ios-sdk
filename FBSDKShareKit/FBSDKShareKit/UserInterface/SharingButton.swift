/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 The common interface for sharing buttons.

 See FBSendButton and FBShareButton
 */
@objc(FBSDKSharingButton)
@available(tvOS, unavailable)
public protocol SharingButton {
  /// The content to be shared.
  var shareContent: SharingContent? { get set }
}
