/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

#if !os(tvOS)

/**
 A delegate for `GameRequestDialog`.

 The delegate is notified with the results of the game request as long as the application has permissions to
 receive the information.  For example, if the person is not signed into the containing app, the shower may not be able
 to distinguish between completion of a game request and cancellation.
 */
@objc(FBSDKGameRequestDialogDelegate)
public protocol GameRequestDialogDelegate: AnyObject {

  /**
   Sent to the delegate when the game request completes without error.
   @param gameRequestDialog The `GameRequestDialog` that completed.
   @param results The results from the dialog.  This may be nil or empty.
   */
  @objc(gameRequestDialog:didCompleteWithResults:)
  func gameRequestDialog(
    _ gameRequestDialog: GameRequestDialog,
    didCompleteWithResults results: [String: Any]
  )

  /**
   Sent to the delegate when the game request encounters an error.
   @param gameRequestDialog The `GameRequestDialog` that completed.
   @param error The error.
   */
  @objc(gameRequestDialog:didFailWithError:)
  func gameRequestDialog(
    _ gameRequestDialog: GameRequestDialog,
    didFailWithError error: Error
  )

  /**
   Sent to the delegate when the game request dialog is cancelled.
   @param gameRequestDialog The `GameRequestDialog` that completed.
   */
  func gameRequestDialogDidCancel(_ gameRequestDialog: GameRequestDialog)
}

#endif
