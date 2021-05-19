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

import XCTest

@available(iOS 12.2, *)
extension PaymentProductRequestorTests {
  struct PaymentProductParameters: Codable, Equatable {
    let contentID: String?
    let productType: String?
    let numberOfItems: Int?
    let transactionDate: String?
    let transactionID: String?
    let currency: String?
    let productTitle: String?
    let description: String?
    let subscriptionPeriod: String?
    let isStartTrial: String?
    let isFreeTrial: String?
    let trialPeriod: String?
    let trialPrice: Int?
    let isImplicitlyLogged: String?
    let receiptData: String?
    let passThroughParameter: String?

    init(
      contentID: String? = nil,
      productType: String? = nil,
      numberOfItems: Int? = nil,
      transactionDate: String? = nil,
      transactionID: String? = nil,
      currency: String? = nil,
      productTitle: String? = nil,
      description: String? = nil,
      subscriptionPeriod: String? = nil,
      isStartTrial: String? = nil,
      isFreeTrial: String? = nil,
      trialPeriod: String? = nil,
      trialPrice: Int? = nil,
      isImplicitlyLogged: String? = nil,
      receiptData: String? = nil,
      passThroughParameter: String? = nil
    ) {
      self.contentID = contentID
      self.productType = productType
      self.numberOfItems = numberOfItems
      self.transactionDate = transactionDate
      self.transactionID = transactionID
      self.currency = currency
      self.productTitle = productTitle
      self.description = description
      self.subscriptionPeriod = subscriptionPeriod
      self.isStartTrial = isStartTrial
      self.isFreeTrial = isFreeTrial
      self.trialPeriod = trialPeriod
      self.trialPrice = trialPrice
      self.isImplicitlyLogged = isImplicitlyLogged
      self.receiptData = receiptData
      self.passThroughParameter = passThroughParameter
    }

    enum CodingKeys: String, CodingKey {
      case contentID = "fb_content_id"
      case productType = "fb_iap_product_type"
      case numberOfItems = "fb_num_items"
      case transactionDate = "fb_transaction_date"
      case transactionID = "fb_transaction_id"
      case currency = "fb_currency"
      case productTitle = "fb_content_title"
      case description = "fb_description"
      case subscriptionPeriod = "fb_iap_subs_period"
      case isStartTrial = "fb_iap_is_start_trial"
      case isFreeTrial = "fb_iap_has_free_trial"
      case trialPeriod = "fb_iap_trial_period"
      case trialPrice = "fb_iap_trial_price"
      case isImplicitlyLogged = "_implicitlyLogged"
      case receiptData = "receipt_data"
      case passThroughParameter = "some_parameter"
    }
  }
}
