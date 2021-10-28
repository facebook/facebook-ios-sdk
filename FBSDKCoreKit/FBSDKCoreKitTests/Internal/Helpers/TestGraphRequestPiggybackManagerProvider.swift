/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestGraphRequestPiggybackManagerProvider: NSObject, GraphRequestPiggybackManagerProviding {

  /// Returns the class TestGraphRequestPiggybackManager. This will need to be reset between tests.
  static func piggybackManager() -> GraphRequestPiggybackManaging.Type {
    TestGraphRequestPiggybackManager.self
  }
}
