/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objc(FBSDKBlocklistEventsManager)
final class BlocklistEventsManager: NSObject, _EventsProcessing {

  var configuredDependencies: ObjectDependencies?

  var defaultDependencies: ObjectDependencies? = .init(
    serverConfigurationProvider: _ServerConfigurationManager.shared
  )

  func enable() {
    // TODO: Implement this
  }

  func processEvents(_ events: NSMutableArray) {
    // TODO: Implement this
  }
}

extension BlocklistEventsManager: DependentAsObject {
  struct ObjectDependencies {
    var serverConfigurationProvider: _ServerConfigurationProviding
  }
}
