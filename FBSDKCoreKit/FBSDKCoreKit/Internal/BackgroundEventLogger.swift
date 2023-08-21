/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

struct BackgroundEventLogger: BackgroundEventLogging {

  private enum Keys {
    static let schedulerIdentifiers = "BGTaskSchedulerPermittedIdentifiers"
  }

  var isNewBackgroundRefresh: Bool {
    let infoDictionaryProvider = Self.infoDictionaryProvider
    return infoDictionaryProvider?.fb_object(forInfoDictionaryKey: Keys.schedulerIdentifiers) != nil
  }

  func logBackgroundRefreshStatus(_ status: UIBackgroundRefreshStatus) {
    let eventLogger = Self.eventLogger

    switch status {
    case .available:
      eventLogger?.logInternalEvent(
        .backgroundStatusAvailable,
        parameters: [.version: isNewBackgroundRefresh],
        isImplicitlyLogged: true
      )
    case .denied:
      eventLogger?.logInternalEvent(.backgroundStatusDenied, isImplicitlyLogged: true)
    case .restricted:
      eventLogger?.logInternalEvent(.backgroundStatusRestricted, isImplicitlyLogged: true)
    @unknown default:
      break
    }
  }
}

extension BackgroundEventLogger: DependentAsType {
  struct TypeDependencies {
    var infoDictionaryProvider: InfoDictionaryProviding
    var eventLogger: EventLogging
  }

  static var configuredDependencies: TypeDependencies?

  static var defaultDependencies: TypeDependencies? = TypeDependencies(
    infoDictionaryProvider: Bundle.main,
    eventLogger: AppEvents.shared
  )
}

extension AppEvents.ParameterName {
  fileprivate static let version = Self("version")
}
