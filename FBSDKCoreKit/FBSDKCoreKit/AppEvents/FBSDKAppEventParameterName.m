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

#import "FBSDKAppEventParameterName.h"

// MARK: - General

// Public

FBSDKAppEventParameterName const FBSDKAppEventParameterNameCurrency = @"fb_currency";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameRegistrationMethod = @"fb_registration_method";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameContentType = @"fb_content_type";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameContent = @"fb_content";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameContentID = @"fb_content_id";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameSearchString = @"fb_search_string";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameSuccess = @"fb_success";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameMaxRatingValue = @"fb_max_rating_value";
FBSDKAppEventParameterName const FBSDKAppEventParameterNamePaymentInfoAvailable = @"fb_payment_info_available";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameNumItems = @"fb_num_items";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameLevel = @"fb_level";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameDescription = @"fb_description";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameAdType = @"ad_type";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameOrderID = @"fb_order_id";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameEventName = @"_eventName";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameLogTime = @"_logTime";

// Internal

FBSDKAppEventParameterName const FBSDKAppEventParameterNameImplicitlyLogged = @"_implicitlyLogged";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameInBackground = @"_inBackground";

// MARK: - Push Notifications

// Internal

FBSDKAppEventParameterName const FBSDKAppEventParameterNamePushCampaign = @"fb_push_campaign";
FBSDKAppEventParameterName const FBSDKAppEventParameterNamePushAction = @"fb_push_action";

// MARK: - E-Commerce

// Internal

FBSDKAppEventParameterName const FBSDKAppEventParameterNameImplicitlyLoggedPurchase = @"_implicitlyLogged";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameInAppPurchaseType = @"fb_iap_product_type";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameProductTitle = @"fb_content_title";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameTransactionID = @"fb_transaction_id";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameTransactionDate = @"fb_transaction_date";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameSubscriptionPeriod = @"fb_iap_subs_period";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameIsStartTrial = @"fb_iap_is_start_trial";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameHasFreeTrial = @"fb_iap_has_free_trial";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameTrialPeriod = @"fb_iap_trial_period";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameTrialPrice = @"fb_iap_trial_price";

// MARK: - Time Spent

// Internal

FBSDKAppEventParameterName const FBSDKAppEventParameterNameSessionInterruptions = @"fb_mobile_app_interruptions";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameTimeBetweenSessions = @"fb_mobile_time_between_sessions";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameSessionID = @"_session_id";
FBSDKAppEventParameterName const FBSDKAppEventParameterNameLaunchSource = @"fb_mobile_launch_source";
