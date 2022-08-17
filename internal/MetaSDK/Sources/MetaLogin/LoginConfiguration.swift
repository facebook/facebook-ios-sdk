/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// A configuration to use for modifying the behavior of a login attempt.
public struct LoginConfiguration {
  var configuredDependencies: InstanceDependencies?
  var defaultDependencies: InstanceDependencies? = InstanceDependencies(
    appConfigurationInquirer: Bundle.main
  )

  private let customFacebookAppID: String?
  private let customMetaAppID: String?

  /// The requested permissions for the login attempt. Defaults to an empty set.
  public let permissions: Set<Permission>

  /// The Facebook App ID used by the SDK.
  /// If not explicitly set, the default will be read from the application's plist (FacebookAppID).
  /// See setup documentation for instructions
  public var facebookAppID: String? {
    customFacebookAppID ?? getAppConfigurationFacebookAppID()
  }

  /// The Meta App ID used by the SDK.
  /// If not explicitly set, the default will be read from the application's plist (MetaAppID).
  /// See setup documentation for instructions
  public var metaAppID: String? {
    customMetaAppID ?? getAppConfigurationMetaAppID()
  }

  /**
   Attempts to initialize a new configuration with the expected parameters.

   - Parameter permissions: The requested permissions for a login attempt.
   - Parameter facebookAppID: the Facebook App ID used by the SDK. If not explicitly set, the default will be read
   from the application's plist (FacebookAppID)
   - Parameter metaAppID: the Meta App ID used by the SDK. If not explicitly set, the default will be read from the
   application's plist (MetaAppID)
   */
  public init(
    permissions: Set<Permission> = [],
    facebookAppID: String? = nil,
    metaAppID: String? = nil
  ) {
    self.permissions = permissions
    customFacebookAppID = facebookAppID
    customMetaAppID = metaAppID
  }

  func getAppConfigurationFacebookAppID() -> String? {
    // swiftformat:disable:next redundantSelf
    self.appConfigurationInquirer?.facebookAppID
  }

  func getAppConfigurationMetaAppID() -> String? {
    // swiftformat:disable:next redundantSelf
    self.appConfigurationInquirer?.metaAppID
  }
}

extension LoginConfiguration: DependentAsInstance {
  struct InstanceDependencies {
    var appConfigurationInquirer: AppConfigurationQuerying
  }
}
