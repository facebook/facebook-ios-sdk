/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Errors representing a failure to create a CustomUpdateContent object
 */
public enum CustomUpdateContentError: Error {
  case notInGameContext
  case invalidMessage
  case invalidMedia
  case invalidImage
}
