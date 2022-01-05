/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

@objc(FBSDKFriendFinderDialog)
public class FriendFinderDialog: NSObject {

  let factory: _GamingServiceControllerCreating

  // Transitional singleton introduced as a way to change the usage semantics
  // from a type-based interface to an instance-based interface.
  static let shared = FriendFinderDialog()

  public override convenience init() {
    self.init(gamingServiceControllerFactory: _GamingServiceControllerFactory())
  }

  init(gamingServiceControllerFactory: _GamingServiceControllerCreating) {
    factory = gamingServiceControllerFactory
  }

  @objc(launchFriendFinderDialogWithCompletionHandler:)
  public static func launch(completionHandler: @escaping GamingServiceCompletionHandler) {
    shared.launch(completionHandler: completionHandler)
  }

  func launch(completionHandler: @escaping GamingServiceCompletionHandler) {
    guard let appID = Settings.shared.appID ?? AccessToken.current?.appID else {
      let error = ErrorFactory().error(
        code: CoreError.errorAccessTokenRequired.rawValue,
        userInfo: nil,
        message: "A valid access token is required to launch the Friend Finder",
        underlyingError: nil
      )
      completionHandler(false, error)
      return
    }

    let controller = factory.create(serviceType: .friendFinder, pendingResult: nil) { success, _, error in
      completionHandler(success, error)
    }

    controller.call(withArgument: appID)
  }
}
