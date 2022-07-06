/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKGamingServicesKit

final class TestGameRequestDialogDelegate: GameRequestDialogDelegate {

  // MARK: Completion

  var completionDialog: GameRequestDialog?
  var completionResults: [String: Any]?

  func gameRequestDialog(
    _ gameRequestDialog: GameRequestDialog,
    didCompleteWithResults results: [String: Any]
  ) {
    completionDialog = gameRequestDialog
    completionResults = results
  }

  // MARK: Failure

  var failureDialog: GameRequestDialog?
  var failureError: Error?

  func gameRequestDialog(
    _ gameRequestDialog: GameRequestDialog,
    didFailWithError error: Error
  ) {
    failureDialog = gameRequestDialog
    failureError = error
  }

  // MARK: Cancellation

  var cancellationDialog: GameRequestDialog?

  func gameRequestDialogDidCancel(_ gameRequestDialog: GameRequestDialog) {
    cancellationDialog = gameRequestDialog
  }
}
