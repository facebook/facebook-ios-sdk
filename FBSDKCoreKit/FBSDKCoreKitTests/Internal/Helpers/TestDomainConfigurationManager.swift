/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

final class TestDomainConfigurationManager: _DomainConfigurationManager {
  var clearCacheCalled = false
  var loadDomainConfigurationWasCalled = false
  var capturedRequestFactory: GraphRequestFactoryProtocol?
  var capturedConnectionFactory: GraphRequestConnectionFactoryProtocol?
  var shouldExecuteCompletion = false

  convenience init() {
    self.init(shouldExecuteCompletion: false)
  }

  convenience init(shouldExecuteCompletion: Bool) {
    self.init(
      domainInfo: _DomainConfiguration.default().domainInfo,
      shouldExecuteCompletion: shouldExecuteCompletion
    )
  }

  convenience init(domainInfo: [String: [String: Any]]?) {
    self.init(domainInfo: domainInfo, shouldExecuteCompletion: false)
  }

  init(domainInfo: [String: [String: Any]]?, shouldExecuteCompletion: Bool) {
    self.shouldExecuteCompletion = shouldExecuteCompletion
    var domainConfig: _DomainConfiguration?
    if let domainInfo = domainInfo {
      domainConfig = _DomainConfiguration(timestamp: nil, domainInfo: domainInfo)
    }
    super.init(domainConfiguration: domainConfig)
  }

  override func cachedDomainConfiguration() -> _DomainConfiguration {
    if let domainConfig = domainConfiguration {
      return domainConfig
    } else {
      return _DomainConfiguration.default()
    }
  }

  override func configure(
    settings: SettingsProtocol,
    dataStore: DataPersisting,
    graphRequestFactory: GraphRequestFactoryProtocol,
    graphRequestConnectionFactory: GraphRequestConnectionFactoryProtocol
  ) {
    capturedRequestFactory = graphRequestFactory
    capturedConnectionFactory = graphRequestConnectionFactory
    super.configure(
      settings: settings,
      dataStore: dataStore,
      graphRequestFactory: graphRequestFactory,
      graphRequestConnectionFactory: graphRequestConnectionFactory
    )
  }

  override func loadDomainConfiguration(completionBlock: _DomainConfigurationBlock? = nil) {
    loadDomainConfigurationWasCalled = true
    if domainConfiguration == nil {
      domainConfiguration = _DomainConfiguration.default()
    }
    if shouldExecuteCompletion {
      completionBlock?()
    }
  }

  func clearCache() {
    clearCacheCalled = true
  }
}
