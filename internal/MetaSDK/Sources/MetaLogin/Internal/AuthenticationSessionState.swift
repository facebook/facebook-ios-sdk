/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum AuthenticationSessionState: Int {
  /// no login session has started
  case none
  /// login session has started and user is performing login
  case performingLogin
  /// login session was canceled
  case canceled
}
