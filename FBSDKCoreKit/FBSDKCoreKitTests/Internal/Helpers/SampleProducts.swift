/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@available(iOS 11.2, *)
enum SampleProducts {
  static func createValid() -> TestProduct {
    TestProduct()
  }

  static func createValidSubscription() -> TestProduct {
    TestProduct(subscriptionPeriod: createValidSubscriptionPeriod())
  }

  static func createInvalidSubscription() -> TestProduct {
    TestProduct(subscriptionPeriod: createInvalidSubscriptionPeriod())
  }

  static func createSubscription(discount: TestProductDiscount) -> TestProduct {
    TestProduct(subscriptionPeriod: createValidSubscriptionPeriod(), discount: discount)
  }

  private static func createValidSubscriptionPeriod() -> TestProductSubscriptionPeriod {
    TestProductSubscriptionPeriod(
      numberOfUnits: 1
    )
  }

  private static func createInvalidSubscriptionPeriod() -> TestProductSubscriptionPeriod {
    TestProductSubscriptionPeriod(
      numberOfUnits: 0
    )
  }
}
