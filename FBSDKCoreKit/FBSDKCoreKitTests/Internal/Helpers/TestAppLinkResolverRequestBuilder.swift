/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools

class TestAppLinkResolverRequestBuilder: AppLinkResolverRequestBuilding {

  var stubbedGraphRequest = TestGraphRequest()
  var stubbedIdiomSpecificField: String?

  func request(for urls: [URL]) -> GraphRequestProtocol {
    stubbedGraphRequest
  }

  func getIdiomSpecificField() -> String? {
    stubbedIdiomSpecificField
  }
}
