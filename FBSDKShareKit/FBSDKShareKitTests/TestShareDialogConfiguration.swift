/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class TestShareDialogConfiguration: ShareDialogConfigurationProtocol {

  var stubbedShouldUseNativeDialogCompletion = false

  func shouldUseNativeDialog(forDialogName dialogName: String) -> Bool {
    stubbedShouldUseNativeDialogCompletion
  }
}
