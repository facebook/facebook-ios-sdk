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

#import "FBSDKAppEventName+Internal.h"

#pragma mark - General Purpose

// Public

FBSDKAppEventName FBSDKAppEventNameAdClick = @"AdClick";
FBSDKAppEventName FBSDKAppEventNameAdImpression = @"AdImpression";
FBSDKAppEventName FBSDKAppEventNameCompletedRegistration = @"fb_mobile_complete_registration";
FBSDKAppEventName FBSDKAppEventNameCompletedTutorial = @"fb_mobile_tutorial_completion";
FBSDKAppEventName FBSDKAppEventNameContact = @"Contact";
FBSDKAppEventName FBSDKAppEventNameCustomizeProduct = @"CustomizeProduct";
FBSDKAppEventName FBSDKAppEventNameDonate = @"Donate";
FBSDKAppEventName FBSDKAppEventNameFindLocation = @"FindLocation";
FBSDKAppEventName FBSDKAppEventNameRated = @"fb_mobile_rate";
FBSDKAppEventName FBSDKAppEventNameSchedule = @"Schedule";
FBSDKAppEventName FBSDKAppEventNameSearched = @"fb_mobile_search";
FBSDKAppEventName FBSDKAppEventNameStartTrial = @"StartTrial";
FBSDKAppEventName FBSDKAppEventNameSubmitApplication = @"SubmitApplication";
FBSDKAppEventName FBSDKAppEventNameSubscribe = @"Subscribe";
FBSDKAppEventName FBSDKAppEventNameViewedContent = @"fb_mobile_content_view";

#pragma mark - E-Commerce

// Public

FBSDKAppEventName FBSDKAppEventNameAddedPaymentInfo = @"fb_mobile_add_payment_info";
FBSDKAppEventName FBSDKAppEventNameAddedToCart = @"fb_mobile_add_to_cart";
FBSDKAppEventName FBSDKAppEventNameAddedToWishlist = @"fb_mobile_add_to_wishlist";
FBSDKAppEventName FBSDKAppEventNameInitiatedCheckout = @"fb_mobile_initiated_checkout";
FBSDKAppEventName FBSDKAppEventNamePurchased = @"fb_mobile_purchase";

// Internal

FBSDKAppEventName FBSDKAppEventNameProductCatalogUpdate = @"fb_mobile_catalog_update";
FBSDKAppEventName FBSDKAppEventNamePurchaseFailed = @"fb_mobile_purchase_failed";
FBSDKAppEventName FBSDKAppEventNamePurchaseRestored = @"fb_mobile_purchase_restored";

#pragma mark - Gaming

// Public

FBSDKAppEventName FBSDKAppEventNameAchievedLevel = @"fb_mobile_level_achieved";
FBSDKAppEventName FBSDKAppEventNameUnlockedAchievement = @"fb_mobile_achievement_unlocked";
FBSDKAppEventName FBSDKAppEventNameSpentCredits = @"fb_mobile_spent_credits";

#pragma mark - Push Notifications

// Internal

FBSDKAppEventName FBSDKAppEventNamePushTokenObtained = @"fb_mobile_obtain_push_token";
FBSDKAppEventName FBSDKAppEventNamePushOpened = @"fb_mobile_push_opened";

#pragma mark - Time Spent

// Internal

FBSDKAppEventName FBSDKAppEventNameActivatedApp = @"fb_mobile_activate_app";
FBSDKAppEventName FBSDKAppEventNameDeactivatedApp = @"fb_mobile_deactivate_app";
