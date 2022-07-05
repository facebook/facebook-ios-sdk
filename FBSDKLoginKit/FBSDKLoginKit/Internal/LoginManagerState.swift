/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

enum LoginManagerState: Int {
  case idle

  // We received a call to start login.
  case start

  // We're calling out to the Facebook app or Safari to perform a log in
  case performingLogin
}

#endif
