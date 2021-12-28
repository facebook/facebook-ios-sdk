/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class TestEventBinding: EventBinding {
  var trackEventWasCalled = false
  var stubbedPath = [Any]()
  let stubbedEventLogger = TestEventLogger()

  init(view potentialView: UIView? = nil) {
    super.init(json: [:], eventLogger: stubbedEventLogger)

    if let view = potentialView,
       let path = ViewHierarchy.getPath(view) {
      stubbedPath = path
    }
  }

  override var path: [Any] {
    stubbedPath
  }

  override func trackEvent(_ sender: Any?) {
    trackEventWasCalled = true
  }
}
