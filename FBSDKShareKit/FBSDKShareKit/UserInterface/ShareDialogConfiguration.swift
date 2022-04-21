/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit
import Foundation

protocol ShareDialogConfigurationProtocol {
  func shouldUseNativeDialog(forDialogName dialogName: String) -> Bool
  func shouldUseSafariViewController(forDialogName dialogName: String) -> Bool
}

extension ShareDialogConfiguration: ShareDialogConfigurationProtocol {}

#endif
