/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 The result of a completed `GamingWebDialog`
 - warning: INTERNAL - DO NOT USE
 */
public protocol GamingWebDialogSuccess {
  init(_ dict: [String: Any]) throws
}
