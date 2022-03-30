/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBAEMKit
import Foundation

enum SampleAEMSingleEntryRules {

  static let urlRule = _AEMAdvertiserSingleEntryRule(
    with: .caseInsensitiveContains,
    paramKey: "URL",
    linguisticCondition: "thankyou.do",
    numericalCondition: nil,
    arrayCondition: nil
  )

  static let cardTypeRule1 = _AEMAdvertiserSingleEntryRule(
    with: .equal,
    paramKey: "card_type",
    linguisticCondition: "platium",
    numericalCondition: nil,
    arrayCondition: nil
  )

  static let cardTypeRule2 = _AEMAdvertiserSingleEntryRule(
    with: .equal,
    paramKey: "card_type",
    linguisticCondition: "blue_credit",
    numericalCondition: nil,
    arrayCondition: nil
  )

  static let cardTypeRule3 = _AEMAdvertiserSingleEntryRule(
    with: .equal,
    paramKey: "card_type",
    linguisticCondition: "gold_charge",
    numericalCondition: nil,
    arrayCondition: nil
  )

  static let contentCategoryRule = _AEMAdvertiserSingleEntryRule(
    with: .equal,
    paramKey: "content_category",
    linguisticCondition: "demand",
    numericalCondition: nil,
    arrayCondition: nil
  )

  static let contentNameRule = _AEMAdvertiserSingleEntryRule(
    with: .startsWith,
    paramKey: "content_name",
    linguisticCondition: "exit",
    numericalCondition: nil,
    arrayCondition: nil
  )

  static let valueRule = _AEMAdvertiserSingleEntryRule(
    with: .greaterThan,
    paramKey: "amount",
    linguisticCondition: nil,
    numericalCondition: NSNumber(value: 10),
    arrayCondition: nil
  )
}
