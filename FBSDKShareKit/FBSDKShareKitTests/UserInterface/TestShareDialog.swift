/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit
import TestTools

final class TestShareDialog: ShareDialog {
  // swiftlint:disable:next swiftlint_disable_without_this_or_next
  // swiftlint:disable discouraged_optional_boolean
  var stubbedCanShow: Bool?
  var stubbedValidationSucceeds: Bool?
  var wasShowCalled = false
  // swiftlint:enable discouraged_optional_boolean

  convenience init() {
    self.init(
      viewController: nil,
      content: nil,
      delegate: nil
    )
  }

  override var canShow: Bool {
    stubbedCanShow ?? super.canShow
  }

  override func validate() throws {
    struct ValidationError: Error {}

    guard let validationSucceeds = stubbedValidationSucceeds else {
      return try super.validate()
    }

    if validationSucceeds {
      return
    } else {
      throw ValidationError()
    }
  }

  override func show() -> Bool {
    wasShowCalled = true
    return super.show()
  }
}
