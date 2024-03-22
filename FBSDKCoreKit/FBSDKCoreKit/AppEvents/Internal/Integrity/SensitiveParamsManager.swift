/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class SensitiveParamsManager: NSObject, _AppEventsParameterProcessing {

  var configuredDependencies: ObjectDependencies?

  var defaultDependencies: ObjectDependencies? = .init(
    serverConfigurationProvider: _ServerConfigurationManager.shared
  )

  func enable() {
    // TODO: Implement this
  }

  func processParameters(
    _ parameters: [AppEvents.ParameterName: Any]?,
    eventName: AppEvents.Name?
  ) -> [AppEvents.ParameterName: Any]? {
    // TODO: Implement this
    return nil
  }
}

extension SensitiveParamsManager: DependentAsObject {
  struct ObjectDependencies {
    var serverConfigurationProvider: _ServerConfigurationProviding
  }
}
