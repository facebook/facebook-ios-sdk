// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

enum ProductIdentifiers: String, CaseIterable {
  case coffee = "com.facebook.coffeeshop.consumable.coffee"
  case giftCard = "com.facebook.coffeeshop.consumable.giftcard"
  case rewardsCard = "com.facebook.coffeeshop.nonconsumable.rewardscard"
  case coffeeMug = "com.facebook.coffeeshop.nonconsumable.coffeemug"
  case nonRenewingMembership = "com.facebook.coffeeshop.nonrenewable.membership"
  case basicMonthlyMembership = "com.facebook.coffeeshop.autorenewing.basicmembership"
  case premiumMonthlyMembership = "com.facebook.coffeeshop.autorenewing.premiummembership"

  static var allIdentifiers = Self.allCases.map { id in
    id.rawValue
  }
}
