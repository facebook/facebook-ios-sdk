/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class TestIntegrityProcessor: IntegrityProcessing {
  var stubbedParameters = [String: Bool]()

  func processIntegrity(_ potentialParameter: String?) -> Bool {
    guard let parameter = potentialParameter else {
      return false
    }

    return stubbedParameters[parameter] ?? false
  }
}
