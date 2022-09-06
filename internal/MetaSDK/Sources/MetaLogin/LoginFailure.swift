/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

public enum LoginFailure: Error {
  case inProgress
  case sessionStart
  case isCanceled
  case `internal`(Error)
  case unknown
}
