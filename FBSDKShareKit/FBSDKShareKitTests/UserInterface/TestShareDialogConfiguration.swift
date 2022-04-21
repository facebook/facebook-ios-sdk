/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

final class TestShareDialogConfiguration: ShareDialogConfigurationProtocol {

  var stubbedShouldUseNativeDialog = false

  func shouldUseNativeDialog(forDialogName dialogName: String) -> Bool {
    stubbedShouldUseNativeDialog
  }

  var capturedShouldUseSafariViewControllerDialogName: String?
  var stubbedShouldUseSafariViewController = false

  func shouldUseSafariViewController(forDialogName dialogName: String) -> Bool {
    capturedShouldUseSafariViewControllerDialogName = dialogName
    return stubbedShouldUseSafariViewController
  }
}
