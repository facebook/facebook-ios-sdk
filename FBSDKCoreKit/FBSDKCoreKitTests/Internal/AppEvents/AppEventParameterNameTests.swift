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

final class AppEventParameterNameTests: XCTestCase {
  func testGeneralRawValues() {
    // Public
    XCTAssertEqual(AppEvents.ParameterName.currency.rawValue, "fb_currency")
    XCTAssertEqual(AppEvents.ParameterName.registrationMethod.rawValue, "fb_registration_method")
    XCTAssertEqual(AppEvents.ParameterName.contentType.rawValue, "fb_content_type")
    XCTAssertEqual(AppEvents.ParameterName.content.rawValue, "fb_content")
    XCTAssertEqual(AppEvents.ParameterName.contentID.rawValue, "fb_content_id")
    XCTAssertEqual(AppEvents.ParameterName.searchString.rawValue, "fb_search_string")
    XCTAssertEqual(AppEvents.ParameterName.success.rawValue, "fb_success")
    XCTAssertEqual(AppEvents.ParameterName.maxRatingValue.rawValue, "fb_max_rating_value")
    XCTAssertEqual(AppEvents.ParameterName.paymentInfoAvailable.rawValue, "fb_payment_info_available")
    XCTAssertEqual(AppEvents.ParameterName.numItems.rawValue, "fb_num_items")
    XCTAssertEqual(AppEvents.ParameterName.level.rawValue, "fb_level")
    XCTAssertEqual(AppEvents.ParameterName.description.rawValue, "fb_description")
    XCTAssertEqual(AppEvents.ParameterName.adType.rawValue, "ad_type")
    XCTAssertEqual(AppEvents.ParameterName.orderID.rawValue, "fb_order_id")
    XCTAssertEqual(AppEvents.ParameterName.eventName.rawValue, "_eventName")
    XCTAssertEqual(AppEvents.ParameterName.logTime.rawValue, "_logTime")

    // Internal
    XCTAssertEqual(AppEvents.ParameterName.implicitlyLogged.rawValue, "_implicitlyLogged")
    XCTAssertEqual(AppEvents.ParameterName.inBackground.rawValue, "_inBackground")
  }

  func testPushNotificationRawValues() {
    // Internal
    XCTAssertEqual(AppEvents.ParameterName.pushCampaign.rawValue, "fb_push_campaign")
    XCTAssertEqual(AppEvents.ParameterName.pushAction.rawValue, "fb_push_action")
  }

  func testECommerceRawValues() {
    // Internal
    XCTAssertEqual(AppEvents.ParameterName.implicitlyLoggedPurchase.rawValue, "_implicitlyLogged")
    XCTAssertEqual(AppEvents.ParameterName.inAppPurchaseType.rawValue, "fb_iap_product_type")
    XCTAssertEqual(AppEvents.ParameterName.productTitle.rawValue, "fb_content_title")
    XCTAssertEqual(AppEvents.ParameterName.transactionID.rawValue, "fb_transaction_id")
    XCTAssertEqual(AppEvents.ParameterName.transactionDate.rawValue, "fb_transaction_date")
    XCTAssertEqual(AppEvents.ParameterName.subscriptionPeriod.rawValue, "fb_iap_subs_period")
    XCTAssertEqual(AppEvents.ParameterName.isStartTrial.rawValue, "fb_iap_is_start_trial")
    XCTAssertEqual(AppEvents.ParameterName.hasFreeTrial.rawValue, "fb_iap_has_free_trial")
    XCTAssertEqual(AppEvents.ParameterName.trialPeriod.rawValue, "fb_iap_trial_period")
    XCTAssertEqual(AppEvents.ParameterName.trialPrice.rawValue, "fb_iap_trial_price")
  }

  func testTimeSpentRawValues() {
    // Internal
    XCTAssertEqual(AppEvents.ParameterName.sessionInterruptions.rawValue, "fb_mobile_app_interruptions")
    XCTAssertEqual(AppEvents.ParameterName.timeBetweenSessions.rawValue, "fb_mobile_time_between_sessions")
    XCTAssertEqual(AppEvents.ParameterName.sessionID.rawValue, "_session_id")
    XCTAssertEqual(AppEvents.ParameterName.launchSource.rawValue, "fb_mobile_launch_source")
  }
}
