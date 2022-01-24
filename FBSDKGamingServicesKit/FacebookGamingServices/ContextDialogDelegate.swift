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
 A delegate for context dialogs to communicate with the dialog handler.
 The delegate is notified with the results of the cross play request as long as the application has permissions to
 receive the information.  For example, if the person is not signed into the containing app, the shower may not be able
 to distinguish between completion of a cross play request and cancellation.
 */
@objc(FBSDKContextDialogDelegate)
public protocol ContextDialogDelegate {

  /**
   Sent to the delegate when the context dialog completes without error.
   @param contextDialog The FBSDKContextDialog that completed.
   */
  func contextDialogDidComplete(_ contextDialog: ContextWebDialog)

  /**
   Sent to the delegate when the context dialog encounters an error.
   @param contextDialog The FBSDKContextDialog that completed.
   @param error The error.
   */
  func contextDialog(_ contextDialog: ContextWebDialog, didFailWithError error: Error)

  /**
   Sent to the delegate when the cross play request dialog is cancelled.
   @param contextDialog The FBSDKContextDialog that completed.
   */
  func contextDialogDidCancel(_ contextDialog: ContextWebDialog)
}

#endif
