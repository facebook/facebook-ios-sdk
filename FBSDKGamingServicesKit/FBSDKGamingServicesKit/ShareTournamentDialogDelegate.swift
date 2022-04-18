/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

public protocol ShareTournamentDialogDelegate: AnyObject {
  func didComplete(dialog: ShareTournamentDialog, tournament: Tournament)
  func didFail(withError error: Error, dialog: ShareTournamentDialog)
  func didCancel(dialog: ShareTournamentDialog)
}
