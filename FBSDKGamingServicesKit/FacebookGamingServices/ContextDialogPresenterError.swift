/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Errors representing a failure to present a context dialog
 */
public enum ContextDialogPresenterError: Error {
  case showCreateContext
  case showSwitchContext
  case showChooseContext
}
