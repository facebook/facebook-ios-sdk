/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

/**
 @methodgroup Predefined event name parameters for common additional information to accompany events logged through the `logEvent` family
 of methods on `FBSDKAppEvents`.  Common event names are provided in the `FBAppEventName*` constants.
 */

/// typedef for FBSDKAppEventParameterName
typedef NSString *FBSDKAppEventParameterName NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(AppEvents.ParameterName);

/**
 * Parameter key used to specify data for the one or more pieces of content being logged about.
 * Data should be a JSON encoded string.
 * Example:
 * "[{\"id\": \"1234\", \"quantity\": 2, \"item_price\": 5.99}, {\"id\": \"5678\", \"quantity\": 1, \"item_price\": 9.99}]"
 */
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameContent;

/// Parameter key used to specify an ID for the specific piece of content being logged about.  Could be an EAN, article identifier, etc., depending on the nature of the app.
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameContentID;

/// Parameter key used to specify a generic content type/family for the logged event, e.g. "music", "photo", "video".  Options to use will vary based upon what the app is all about.
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameContentType;

/// Parameter key used to specify currency used with logged event.  E.g. "USD", "EUR", "GBP".  See ISO-4217 for specific values.  One reference for these is <http://en.wikipedia.org/wiki/ISO_4217>.
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameCurrency;

/// Parameter key used to specify a description appropriate to the event being logged.  E.g., the name of the achievement unlocked in the `FBAppEventNameAchievementUnlocked` event.
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameDescription;

/// Parameter key used to specify the level achieved in a `FBAppEventNameAchieved` event.
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameLevel;

/// Parameter key used to specify the maximum rating available for the `FBAppEventNameRate` event.  E.g., "5" or "10".
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameMaxRatingValue;

/// Parameter key used to specify how many items are being processed for an `FBAppEventNameInitiatedCheckout` or `FBAppEventNamePurchased` event.
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameNumItems;

/// Parameter key used to specify whether payment info is available for the `FBAppEventNameInitiatedCheckout` event.  `FBSDKAppEventParameterValueYes` and `FBSDKAppEventParameterValueNo` are good canonical values to use for this parameter.
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNamePaymentInfoAvailable;

/// Parameter key used to specify method user has used to register for the app, e.g., "Facebook", "email", "Twitter", etc
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameRegistrationMethod;

/// Parameter key used to specify the string provided by the user for a search operation.
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameSearchString;

/// Parameter key used to specify whether the activity being logged about was successful or not.  `FBSDKAppEventParameterValueYes` and `FBSDKAppEventParameterValueNo` are good canonical values to use for this parameter.
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameSuccess;

/** Parameter key used to specify the type of ad in an FBSDKAppEventNameAdImpression
 * or FBSDKAppEventNameAdClick event.
 * E.g. "banner", "interstitial", "rewarded_video", "native" */
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameAdType;

/** Parameter key used to specify the unique ID for all events within a subscription
 * in an FBSDKAppEventNameSubscribe or FBSDKAppEventNameStartTrial event. */
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameOrderID;

/// Parameter key used to specify event name.
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameEventName;

/// Parameter key used to specify event log time.
FOUNDATION_EXPORT FBSDKAppEventParameterName const FBSDKAppEventParameterNameLogTime;
