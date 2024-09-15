/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import StoreKit

struct IAPSubscriptionPeriod: Equatable {
  let unit: IAPSubscriptionPeriodUnit
  let numUnits: Int
}

enum IAPSubscriptionPeriodUnit: String {
  case day = "D"
  case week = "W"
  case month = "M"
  case year = "Y"
  case unknown = ""
}

@available(iOS 15.0, *)
extension Product.SubscriptionPeriod {
  var iapSubscriptionPeriod: IAPSubscriptionPeriod {
    return IAPSubscriptionPeriod(unit: { // swiftlint:disable:this implicit_return
      switch self.unit {
      case .day: return .day
      case .week: return .week
      case .month: return .month
      case .year: return .year
      @unknown default: return .unknown
      }
    }(), numUnits: value)
  }
}

extension SKProductSubscriptionPeriod {
  var iapSubscriptionPeriod: IAPSubscriptionPeriod {
    return IAPSubscriptionPeriod(unit: { // swiftlint:disable:this implicit_return
      switch self.unit {
      case .day: return .day
      case .week: return .week
      case .month: return .month
      case .year: return .year
      @unknown default: return .unknown
      }
    }(), numUnits: numberOfUnits)
  }
}
