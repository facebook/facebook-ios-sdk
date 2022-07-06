/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKShareKit
import Foundation

protocol GamingShareValidating {
  static func validateRequiredValue(_ value: Any, named name: String) throws
}

extension _ShareUtility: GamingShareValidating {}
