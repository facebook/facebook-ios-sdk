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
 A delegate for types conforming to the `Sharing` protocol.

 The delegate is notified with the results of the sharer as long as the application has permissions to
 receive the information.  For example, if the person is not signed into the containing app, the sharer may not be able
 to distinguish between completion of a share and cancellation.
 */
@objc(FBSDKSharingDelegate)
public protocol SharingDelegate {

  /**
   Sent to the delegate when sharing completes without error or cancellation.
   @param sharer The sharer that completed.
   @param results The results from the sharer.  This may be nil or empty.
   */
  @objc(sharer:didCompleteWithResults:)
  func sharer(_ sharer: Sharing, didCompleteWithResults results: [String: Any])

  /**
   Sent to the delegate when the sharer encounters an error.
   @param sharer The sharer that completed.
   @param error The error.
   */
  @objc(sharer:didFailWithError:)
  func sharer(_ sharer: Sharing, didFailWithError error: Error)

  /**
   Sent to the delegate when the sharer is cancelled.
   @param sharer The sharer that completed.
   */
  @objc(sharerDidCancel:)
  func sharerDidCancel(_ sharer: Sharing)
}

#endif
