/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objc(FBSDKPaymentProductRequestorFactory)
public final class _PaymentProductRequestorFactory: NSObject, _PaymentProductRequestorCreating {

  public func createRequestor(transaction: SKPaymentTransaction) -> PaymentProductRequestor {
    guard let dependencies = try? Self.getDependencies() else {
      fatalError("Dependencies have not been set")
    }

    return PaymentProductRequestor(
      transaction: transaction,
      settings: dependencies.settings,
      eventLogger: dependencies.eventLogger,
      gateKeeperManager: dependencies.gateKeeperManager,
      store: dependencies.store,
      loggerFactory: dependencies.loggerFactory,
      productsRequestFactory: dependencies.productsRequestFactory,
      appStoreReceiptProvider: dependencies.appStoreReceiptProvider
    )
  }
}

extension _PaymentProductRequestorFactory: DependentAsType {
  struct TypeDependencies {
    var settings: SettingsProtocol
    var eventLogger: EventLogging
    var gateKeeperManager: _GateKeeperManaging.Type
    var store: DataPersisting
    var loggerFactory: _LoggerCreating
    var productsRequestFactory: _ProductsRequestCreating
    var appStoreReceiptProvider: _AppStoreReceiptProviding
  }

  static var configuredDependencies: TypeDependencies?

  static var defaultDependencies: TypeDependencies? = TypeDependencies(
    settings: Settings.shared,
    eventLogger: AppEvents.shared,
    gateKeeperManager: _GateKeeperManager.self,
    store: UserDefaults.standard,
    loggerFactory: _LoggerFactory(),
    productsRequestFactory: _ProductRequestFactory(),
    appStoreReceiptProvider: Bundle(for: ApplicationDelegate.self)
  )
}
