/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics
import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBSDKFeatureManager)
public final class _FeatureManager: NSObject, FeatureChecking, _FeatureDisabling {
  let featureManagerPrefix = "com.facebook.sdk:FBSDKFeatureManager.FBSDKFeature"

  public static let shared = _FeatureManager()

  public func isEnabled(_ feature: SDKFeature) -> Bool {
    if SDKFeature.core == feature || SDKFeature.none == feature {
      return true
    }

    guard let parentFeature = getParentFeature(for: feature) else {
      return false
    }

    if parentFeature == feature {
      return checkGateKeeper(for: feature)
    } else {
      return isEnabled(parentFeature) && checkGateKeeper(for: feature)
    }
  }

  public func check(_ feature: SDKFeature, completionBlock: @escaping FBSDKFeatureManagerBlock) {
    guard let dependencies = try? Self.getDependencies() else {
      completionBlock(false)
      return
    }

    // check if the feature is locally disabled by Crash Shield first
    let version = dependencies.store.fb_string(forKey: storageKey(for: feature))
    if version == dependencies.settings.sdkVersion {
      completionBlock(false)
      return
    }

    // check gk
    dependencies.gateKeeperManager.loadGateKeepers { _ in
      completionBlock(self.isEnabled(feature))
    }
  }

  public func disableFeature(_ feature: SDKFeature) {
    guard let dependencies = try? Self.getDependencies() else {
      return
    }

    dependencies.store.fb_setObject(dependencies.settings.sdkVersion, forKey: storageKey(for: feature))
  }

  func storageKey(for feature: SDKFeature) -> String {
    featureManagerPrefix + featureName(for: feature)
  }

  func checkGateKeeper(for feature: SDKFeature) -> Bool {
    guard let gateKeeperManager = try? Self.getDependencies().gateKeeperManager else {
      return false
    }

    let featureName = featureName(for: feature)
    let key = "FBSDKFeature\(featureName)"
    let defaultValue = defaultStatus(for: feature)

    return gateKeeperManager.bool(forKey: key, defaultValue: defaultValue)
  }

  func defaultStatus(for feature: SDKFeature) -> Bool {
    switch feature {
    case
      .restrictiveDataFiltering,
      .eventDeactivation,
      .instrument,
      .crashReport,
      .crashShield,
      .errorReport,
      .AAM,
      .privacyProtection,
      .suggestedEvents,
      .intelligentIntegrity,
      .modelRequest,
      .ateLogging,
      .AEM,
      .aemConversionFiltering,
      .aemCatalogMatching,
      .aemAdvertiserRuleMatchInServer,
      .appEventsCloudbridge,
      .skAdNetwork,
      .skAdNetworkConversionValue:
      return false
    case .none, .login, .share, .core, .appEvents, .codelessEvents, .gamingServices:
      return true
    @unknown default:
      return false
    }
  }

  func getParentFeature(for feature: SDKFeature) -> SDKFeature? {
    if feature.rawValue & 0xFF > 0 {
      return SDKFeature(rawValue: feature.rawValue & 0xFFFFFF00)
    } else if feature.rawValue & 0xFF00 > 0 {
      return SDKFeature(rawValue: feature.rawValue & 0xFFFF0000)
    } else if feature.rawValue & 0xFF0000 > 0 {
      return SDKFeature(rawValue: feature.rawValue & 0xFF000000)
    } else {
      return SDKFeature(rawValue: 0)
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  func featureName(for feature: SDKFeature) -> String {
    var featureName: String

    switch feature {
    case .none: featureName = "NONE"
    case .core: featureName = "CoreKit"
    case .appEvents: featureName = "AppEvents"
    case .codelessEvents: featureName = "CodelessEvents"
    case .restrictiveDataFiltering: featureName = "RestrictiveDataFiltering"
    case .AAM: featureName = "AAM"
    case .privacyProtection: featureName = "PrivacyProtection"
    case .suggestedEvents: featureName = "SuggestedEvents"
    case .intelligentIntegrity: featureName = "IntelligentIntegrity"
    case .modelRequest: featureName = "ModelRequest"
    case .eventDeactivation: featureName = "EventDeactivation"
    case .skAdNetwork: featureName = "SKAdNetwork"
    case .skAdNetworkConversionValue: featureName = "SKAdNetworkConversionValue"
    case .instrument: featureName = "Instrument"
    case .crashReport: featureName = "CrashReport"
    case .crashShield: featureName = "CrashShield"
    case .errorReport: featureName = "ErrorReport"
    case .ateLogging: featureName = "ATELogging"
    case .AEM: featureName = "AEM"
    case .aemConversionFiltering: featureName = "AEMConversionFiltering"
    case .aemCatalogMatching: featureName = "AEMCatalogMatching"
    case .aemAdvertiserRuleMatchInServer: featureName = "AEMAdvertiserRuleMatchInServer"
    case .appEventsCloudbridge: featureName = "AppEventsCloudbridge"
    case .login: featureName = "LoginKit"
    case .share: featureName = "ShareKit"
    case .gamingServices: featureName = "GamingServicesKit"
    @unknown default: featureName = "NONE"
    }

    return featureName
  }
}

extension _FeatureManager: DependentAsType {
  struct TypeDependencies {
    var gateKeeperManager: _GateKeeperManaging.Type
    var settings: SettingsProtocol
    var store: DataPersisting
  }

  static var configuredDependencies: TypeDependencies?

  static var defaultDependencies: TypeDependencies? = TypeDependencies(
    gateKeeperManager: _GateKeeperManager.self,
    settings: Settings.shared,
    store: UserDefaults.standard
  )
}
