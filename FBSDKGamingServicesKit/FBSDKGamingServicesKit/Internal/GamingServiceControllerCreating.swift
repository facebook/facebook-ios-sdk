/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

protocol GamingServiceControllerCreating {
  func create(
    serviceType: GamingServiceType,
    pendingResult: [String: Any]?,
    completion: @escaping GamingServiceResultCompletion
  ) -> GamingServiceControllerProtocol
}
