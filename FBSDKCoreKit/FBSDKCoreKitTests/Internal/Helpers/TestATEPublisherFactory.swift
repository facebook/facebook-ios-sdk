/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestATEPublisherFactory: NSObject, ATEPublisherCreating {
  var stubbedPublisher: ATEPublishing? = TestATEPublisher()
  var capturedAppID: String?

  func createPublisher(appID: String) -> ATEPublishing? {
    capturedAppID = appID
    return stubbedPublisher
  }
}
