/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class TestProductsRequest: ProductsRequest {
  var cancelCallCount = 0
  var startCallCount = 0

  weak var delegate: SKProductsRequestDelegate?

  func cancel() {
    cancelCallCount += 1
  }

  func start() {
    startCallCount += 1
  }
}
