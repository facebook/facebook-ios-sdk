/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

// Hacky subclassing to get around init not being available.
// Future work should update ServerConfigurationProvider to return
// a true abstraction instead of a concrete ServerConfiguration and this
// type should simply conform to that abstraction.
class TestServerConfiguration: ServerConfiguration {
  var capturedUseNativeDialogName: String?
  var capturedUseSafariControllerName: String?
  var stubbedDefaultShareMode: String?
  @objc var stubbedIsCodelessEventsEnabled = false

  @objc
  convenience init(
    appID: String = "123"
  ) {
    self.init(
      appID: appID,
      appName: nil,
      loginTooltipEnabled: true,
      loginTooltipText: nil,
      defaultShareMode: nil,
      advertisingIDEnabled: false,
      implicitLoggingEnabled: false,
      implicitPurchaseLoggingEnabled: false,
      codelessEventsEnabled: false,
      uninstallTrackingEnabled: false,
      dialogConfigurations: [:],
      dialogFlows: [:],
      timestamp: Date(),
      errorConfiguration: nil,
      sessionTimeoutInterval: 1,
      defaults: false,
      loggingToken: nil,
      smartLoginOptions: .enabled,
      smartLoginBookmarkIconURL: nil,
      smartLoginMenuIconURL: nil,
      updateMessage: nil,
      eventBindings: nil,
      restrictiveParams: nil,
      aamRules: nil,
      suggestedEventsSetting: nil
    )
  }

  override var isCodelessEventsEnabled: Bool {
    stubbedIsCodelessEventsEnabled
  }

  override var defaultShareMode: String? {
    stubbedDefaultShareMode
  }

  override func useNativeDialog(
    forDialogName dialogName: String?
  ) -> Bool {
    capturedUseNativeDialogName = dialogName
    return true
  }

  override func useSafariViewController(
    forDialogName dialogName: String?
  ) -> Bool {
    capturedUseSafariControllerName = dialogName
    return true
  }
}
