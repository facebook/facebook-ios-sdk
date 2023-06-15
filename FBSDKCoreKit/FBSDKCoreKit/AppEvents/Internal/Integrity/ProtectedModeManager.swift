/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class ProtectedModeManager: _AppEventsParameterProcessing {
  private var isEnabled = false

  func enable() {
    isEnabled = true
  }

  func processParameters(
    _ parameters: [AppEvents.ParameterName: Any]?,
    eventName: AppEvents.Name
  ) -> [AppEvents.ParameterName: Any]? {
    // stub
    return parameters
  }
}
