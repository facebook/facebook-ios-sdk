/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics
import UIKit

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBSDKViewImpressionLogger)
public final class _ViewImpressionLogger: NSObject, ImpressionLogging {
  static var impressionTrackers = [AppEvents.Name: Any]()
  let eventName: AppEvents.Name
  var trackedImpressions = Set<[String: String]>()

  @objc(initWithEventName:)
  public init(eventName: AppEvents.Name) {
    self.eventName = eventName

    super.init()

    guard let notificationDeliverer = try? Self.getDependencies().notificationDeliverer else {
      return
    }

    notificationDeliverer.fb_addObserver(
      self,
      selector: #selector(applicationDidEnterBackground(_:)),
      name: UIApplication.didEnterBackgroundNotification,
      object: UIApplication.shared
    )
  }

  public static func retrieveLogger(with eventName: AppEvents.Name) -> _ViewImpressionLogger {
    if let impressionLogger = Self.impressionTrackers[eventName] as? _ViewImpressionLogger {
      return impressionLogger
    }
    let impressionLogger = _ViewImpressionLogger(eventName: eventName)
    Self.impressionTrackers[eventName] = impressionLogger
    return impressionLogger
  }

  func applicationDidEnterBackground(_ notification: Notification) {
    trackedImpressions.removeAll()
  }

  public func logImpression(withIdentifier identifier: String, parameters: [AppEvents.ParameterName: Any]?) {
    guard let dependencies = try? Self.getDependencies() else {
      return
    }

    var keys = [String: String]()
    keys["__view_impression_identifier__"] = identifier

    if let parameters = parameters as? [AppEvents.ParameterName: String] {
      parameters.forEach { key, value in keys[key.rawValue] = value }
    }

    // Ensure that each impression is only tracked once
    if trackedImpressions.contains(keys) {
      return
    }

    trackedImpressions.insert(keys)
    dependencies.eventLogger.logInternalEvent(
      eventName,
      parameters: parameters,
      isImplicitlyLogged: true,
      accessToken: dependencies.tokenWallet.current
    )
  }
}

extension _ViewImpressionLogger: DependentAsType {
  struct TypeDependencies {
    var graphRequestFactory: GraphRequestFactoryProtocol
    var eventLogger: EventLogging
    var notificationDeliverer: NotificationDelivering
    var tokenWallet: AccessTokenProviding.Type
  }

  static var configuredDependencies: TypeDependencies?

  static var defaultDependencies: TypeDependencies? = TypeDependencies(
    graphRequestFactory: GraphRequestFactory(),
    eventLogger: AppEvents.shared,
    notificationDeliverer: NotificationCenter.default,
    tokenWallet: AccessToken.self
  )
}
