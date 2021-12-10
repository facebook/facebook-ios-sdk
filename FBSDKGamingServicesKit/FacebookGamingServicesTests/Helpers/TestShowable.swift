/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookGamingServices

class TestShowable: Showable {
  var wasShowCalled = false
  var canShow = false

  func show() -> Bool {
    wasShowCalled = true

    return canShow
  }
}
