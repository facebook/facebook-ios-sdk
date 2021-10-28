/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

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
