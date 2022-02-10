/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class TestPaymentProductRequestor: PaymentProductRequestor {
  var wasResolveProductsCalled = false

  override func resolveProducts() {
    wasResolveProductsCalled = true
  }
}
