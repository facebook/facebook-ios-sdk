/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
@objc(FBSDKGamingGroupIntegration)
public final class GamingGroupIntegration: NSObject {

  let settings: SettingsProtocol
  let serviceControllerFactory: GamingServiceControllerCreating

  override convenience init() {
    self.init(
      settings: Settings.shared,
      serviceControllerFactory: GamingServiceControllerFactory()
    )
  }

  init(settings: SettingsProtocol, serviceControllerFactory: GamingServiceControllerCreating) {
    self.settings = settings
    self.serviceControllerFactory = serviceControllerFactory
  }

  public static func openGroupPage(completionHandler: @escaping GamingServiceCompletionHandler) {
    let integration = GamingGroupIntegration()
    integration.openGroupPage(completionHandler: completionHandler)
  }

  func openGroupPage(completionHandler: @escaping GamingServiceCompletionHandler) {
    let controller = serviceControllerFactory.create(serviceType: .community, pendingResult: nil) { success, _, error in
      completionHandler(success, error)
    }

    controller.call(withArgument: settings.appID)
  }
}
