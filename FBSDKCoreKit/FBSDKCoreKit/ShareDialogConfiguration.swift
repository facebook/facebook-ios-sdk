/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 Describe known values for dialog configurations.

 Internal Use Only
 */
public enum DialogConfigurationName {
  public static let message = "message"
  public static let share = "share"
}

/**
 A lightweight interface to expose aspects of ServerConfiguration that are used by dialogs in ShareKit.

 Internal Use Only
 */
@available(tvOS, unavailable)
public struct ShareDialogConfiguration {

  var configuredDependencies: InstanceDependencies?

  var defaultDependencies: InstanceDependencies? = InstanceDependencies(
    serverConfigurationProvider: _ServerConfigurationManager.shared
  )

  public init() {}

  public var defaultShareMode: String? {
    guard let dependencies = try? getDependencies() else { return nil }

    return dependencies.serverConfigurationProvider.cachedServerConfiguration().defaultShareMode
  }

  public func shouldUseNativeDialog(forDialogName dialogName: String) -> Bool {
    guard let dependencies = try? getDependencies() else { return false }

    return dependencies.serverConfigurationProvider
      .cachedServerConfiguration()
      .useNativeDialog(forDialogName: dialogName)
  }

  public func shouldUseSafariViewController(forDialogName dialogName: String) -> Bool {
    guard let dependencies = try? getDependencies() else { return false }

    return dependencies.serverConfigurationProvider
      .cachedServerConfiguration()
      .useSafariViewController(forDialogName: dialogName)
  }
}

@available(tvOS, unavailable)
extension ShareDialogConfiguration: DependentAsInstance {
  struct InstanceDependencies {
    var serverConfigurationProvider: _ServerConfigurationProviding
  }
}
