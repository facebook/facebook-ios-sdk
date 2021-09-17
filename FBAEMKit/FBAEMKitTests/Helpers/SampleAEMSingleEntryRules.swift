// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FBAEMKit
import Foundation

enum SampleAEMSingleEntryRules {

  static let urlRule = AEMAdvertiserSingleEntryRule(
    with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorI_Contains,
    paramKey: "URL",
    linguisticCondition: "thankyou.do",
    numericalCondition: nil,
    arrayCondition: nil
  )

  static let cardTypeRule1 = AEMAdvertiserSingleEntryRule(
    with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorEqual,
    paramKey: "card_type",
    linguisticCondition: "platium",
    numericalCondition: nil,
    arrayCondition: nil
  )

  static let cardTypeRule2 = AEMAdvertiserSingleEntryRule(
    with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorEqual,
    paramKey: "card_type",
    linguisticCondition: "blue_credit",
    numericalCondition: nil,
    arrayCondition: nil
  )

  static let cardTypeRule3 = AEMAdvertiserSingleEntryRule(
    with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorEqual,
    paramKey: "card_type",
    linguisticCondition: "gold_charge",
    numericalCondition: nil,
    arrayCondition: nil
  )

  static let contentCategoryRule = AEMAdvertiserSingleEntryRule(
    with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorEqual,
    paramKey: "content_category",
    linguisticCondition: "demand",
    numericalCondition: nil,
    arrayCondition: nil
  )

  static let contentNameRule = AEMAdvertiserSingleEntryRule(
    with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorStartsWith,
    paramKey: "content_name",
    linguisticCondition: "exit",
    numericalCondition: nil,
    arrayCondition: nil
  )

  static let valueRule = AEMAdvertiserSingleEntryRule(
    with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorGreaterThan,
    paramKey: "amount",
    linguisticCondition: nil,
    numericalCondition: NSNumber(value: 10),
    arrayCondition: nil
  )
}
