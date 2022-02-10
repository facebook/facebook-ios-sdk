/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@available(iOS 11.2, *)
final class TestProductSubscriptionPeriod: SKProductSubscriptionPeriod {
  let stubbedNumberOfUnits: Int

  init(numberOfUnits: Int) {
    stubbedNumberOfUnits = numberOfUnits
  }

  override var numberOfUnits: Int {
    stubbedNumberOfUnits
  }
}
