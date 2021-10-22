/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
class TestGamingServiceController: NSObject, GamingServiceControllerProtocol {
  var capturedArgument: String?

  func call(withArgument argument: String?) {
    capturedArgument = argument
  }
}

@objcMembers
class TestGamingServiceControllerFactory: NSObject, GamingServiceControllerCreating {

  var capturedServiceType: GamingServiceType = .friendFinder
  var capturedCompletion: GamingServiceResultCompletion = { _, _, _ in }
  var capturedPendingResult: Any?
  var controller = TestGamingServiceController()

  func create(
    with serviceType: GamingServiceType,
    completion: @escaping GamingServiceResultCompletion,
    pendingResult: Any?
  ) -> GamingServiceControllerProtocol {
    capturedServiceType = serviceType
    capturedCompletion = completion
    capturedPendingResult = pendingResult

    return controller
  }
}
