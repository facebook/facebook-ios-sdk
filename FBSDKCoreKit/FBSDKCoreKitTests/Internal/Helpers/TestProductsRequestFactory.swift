/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class TestProductsRequestFactory: ProductsRequestCreating {
  let request = TestProductsRequest()
  var capturedProductIdentifiers = Set<String>()

  func create(withProductIdentifiers identifiers: Set<String>) -> ProductsRequest {
    capturedProductIdentifiers.formUnion(identifiers)
    return request
  }
}
