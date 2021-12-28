/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookGamingServices
import FBSDKCoreKit

// Internal protocol to enable us to verify that the underlying pure Swift type is
// exercised correctly by the wrapper class
protocol SwitchContextDialogProtocol: WebDialogDelegate, DialogProtocol {

  var currentWebDialog: WebDialog? { get set }

  func createWebDialogFrame(
    withWidth: CGFloat,
    height: CGFloat,
    windowFinder: WindowFinding
  ) -> CGRect
}

extension SwitchContextDialog: SwitchContextDialogProtocol {}
