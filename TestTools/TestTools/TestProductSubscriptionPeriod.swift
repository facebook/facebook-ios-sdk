/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import StoreKit

public final class TestProductSubscriptionPeriod: SKProductSubscriptionPeriod {
  public let stubbedNumberOfUnits: Int
  public let stubbedUnit: SKProduct.PeriodUnit

  public init(
    numberOfUnits: Int,
    unit: SKProduct.PeriodUnit = SKProduct.PeriodUnit.day
  ) {
    stubbedNumberOfUnits = numberOfUnits
    stubbedUnit = unit
  }

  public override var numberOfUnits: Int {
    stubbedNumberOfUnits
  }

  public override var unit: SKProduct.PeriodUnit {
    stubbedUnit
  }
}
