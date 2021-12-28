/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppEventName+Internal.h"

// MARK: - General Purpose

// Public

FBSDKAppEventName const FBSDKAppEventNameAdClick = @"AdClick";
FBSDKAppEventName const FBSDKAppEventNameAdImpression = @"AdImpression";
FBSDKAppEventName const FBSDKAppEventNameCompletedRegistration = @"fb_mobile_complete_registration";
FBSDKAppEventName const FBSDKAppEventNameCompletedTutorial = @"fb_mobile_tutorial_completion";
FBSDKAppEventName const FBSDKAppEventNameContact = @"Contact";
FBSDKAppEventName const FBSDKAppEventNameCustomizeProduct = @"CustomizeProduct";
FBSDKAppEventName const FBSDKAppEventNameDonate = @"Donate";
FBSDKAppEventName const FBSDKAppEventNameFindLocation = @"FindLocation";
FBSDKAppEventName const FBSDKAppEventNameRated = @"fb_mobile_rate";
FBSDKAppEventName const FBSDKAppEventNameSchedule = @"Schedule";
FBSDKAppEventName const FBSDKAppEventNameSearched = @"fb_mobile_search";
FBSDKAppEventName const FBSDKAppEventNameStartTrial = @"StartTrial";
FBSDKAppEventName const FBSDKAppEventNameSubmitApplication = @"SubmitApplication";
FBSDKAppEventName const FBSDKAppEventNameSubscribe = @"Subscribe";
FBSDKAppEventName const FBSDKAppEventNameViewedContent = @"fb_mobile_content_view";

// MARK: - Application Lifecycle

// Internal

FBSDKAppEventName const FBSDKAppEventNameInitializeSDK = @"fb_sdk_initialize";
FBSDKAppEventName const FBSDKAppEventNameBackgroundStatusAvailable = @"fb_sdk_background_status_available";
FBSDKAppEventName const FBSDKAppEventNameBackgroundStatusDenied = @"fb_sdk_background_status_denied";
FBSDKAppEventName const FBSDKAppEventNameBackgroundStatusRestricted = @"fb_sdk_background_status_restricted";

// MARK: - E-Commerce

// Public

FBSDKAppEventName const FBSDKAppEventNameAddedPaymentInfo = @"fb_mobile_add_payment_info";
FBSDKAppEventName const FBSDKAppEventNameAddedToCart = @"fb_mobile_add_to_cart";
FBSDKAppEventName const FBSDKAppEventNameAddedToWishlist = @"fb_mobile_add_to_wishlist";
FBSDKAppEventName const FBSDKAppEventNameInitiatedCheckout = @"fb_mobile_initiated_checkout";
FBSDKAppEventName const FBSDKAppEventNamePurchased = @"fb_mobile_purchase";

// Internal

FBSDKAppEventName const FBSDKAppEventNameProductCatalogUpdate = @"fb_mobile_catalog_update";
FBSDKAppEventName const FBSDKAppEventNamePurchaseFailed = @"fb_mobile_purchase_failed";
FBSDKAppEventName const FBSDKAppEventNamePurchaseRestored = @"fb_mobile_purchase_restored";
FBSDKAppEventName const FBSDKAppEventNameSubscribeInitiatedCheckout = @"SubscriptionInitiatedCheckout";
FBSDKAppEventName const FBSDKAppEventNameSubscribeFailed = @"SubscriptionFailed";
FBSDKAppEventName const FBSDKAppEventNameSubscribeRestore = @"SubscriptionRestore";

// MARK: - Gaming

// Public

FBSDKAppEventName const FBSDKAppEventNameAchievedLevel = @"fb_mobile_level_achieved";
FBSDKAppEventName const FBSDKAppEventNameUnlockedAchievement = @"fb_mobile_achievement_unlocked";
FBSDKAppEventName const FBSDKAppEventNameSpentCredits = @"fb_mobile_spent_credits";

// MARK: - Push Notifications

// Internal

FBSDKAppEventName const FBSDKAppEventNamePushTokenObtained = @"fb_mobile_obtain_push_token";
FBSDKAppEventName const FBSDKAppEventNamePushOpened = @"fb_mobile_push_opened";

// MARK: - Time Spent

// Internal

FBSDKAppEventName const FBSDKAppEventNameActivatedApp = @"fb_mobile_activate_app";
FBSDKAppEventName const FBSDKAppEventNameDeactivatedApp = @"fb_mobile_deactivate_app";
