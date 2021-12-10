/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestAtePublisherFactory: NSObject, AtePublisherCreating {
  var stubbedPublisher: AtePublishing? = TestAtePublisher()
  var capturedAppID: String?

  func createPublisher(appID: String) -> AtePublishing? {
    capturedAppID = appID
    return stubbedPublisher
  }
}
