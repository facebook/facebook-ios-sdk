/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

enum LoginError: Error {
  case invalidIncomingURL
  case invalidURLCreation
  case cancelledLogin
  case unhandledError(message: String?)
}
