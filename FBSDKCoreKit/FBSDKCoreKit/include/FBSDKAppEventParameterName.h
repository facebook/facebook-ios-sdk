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

#import <Foundation/Foundation.h>

/**
 @methodgroup Predefined event name parameters for common additional information to accompany events logged through the `logEvent` family
 of methods on `FBSDKAppEvents`.  Common event names are provided in the `FBAppEventName*` constants.
 */

/// typedef for FBSDKAppEventParameterName
typedef NSString *const FBSDKAppEventParameterName NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(AppEvents.ParameterName);

 /**
  * Parameter key used to specify data for the one or more pieces of content being logged about.
  * Data should be a JSON encoded string.
  * Example:
  * "[{\"id\": \"1234\", \"quantity\": 2, \"item_price\": 5.99}, {\"id\": \"5678\", \"quantity\": 1, \"item_price\": 9.99}]"
  */
FOUNDATION_EXPORT FBSDKAppEventParameterName FBSDKAppEventParameterNameContent;

/** Parameter key used to specify an ID for the specific piece of content being logged about.  Could be an EAN, article identifier, etc., depending on the nature of the app. */
FOUNDATION_EXPORT FBSDKAppEventParameterName FBSDKAppEventParameterNameContentID;

/** Parameter key used to specify a generic content type/family for the logged event, e.g. "music", "photo", "video".  Options to use will vary based upon what the app is all about. */
FOUNDATION_EXPORT FBSDKAppEventParameterName FBSDKAppEventParameterNameContentType;

/** Parameter key used to specify currency used with logged event.  E.g. "USD", "EUR", "GBP".  See ISO-4217 for specific values.  One reference for these is <http://en.wikipedia.org/wiki/ISO_4217>. */
FOUNDATION_EXPORT FBSDKAppEventParameterName FBSDKAppEventParameterNameCurrency;

/** Parameter key used to specify a description appropriate to the event being logged.  E.g., the name of the achievement unlocked in the `FBAppEventNameAchievementUnlocked` event. */
FOUNDATION_EXPORT FBSDKAppEventParameterName FBSDKAppEventParameterNameDescription;

/** Parameter key used to specify the level achieved in a `FBAppEventNameAchieved` event. */
FOUNDATION_EXPORT FBSDKAppEventParameterName FBSDKAppEventParameterNameLevel;

/** Parameter key used to specify the maximum rating available for the `FBAppEventNameRate` event.  E.g., "5" or "10". */
FOUNDATION_EXPORT FBSDKAppEventParameterName FBSDKAppEventParameterNameMaxRatingValue;

/** Parameter key used to specify how many items are being processed for an `FBAppEventNameInitiatedCheckout` or `FBAppEventNamePurchased` event. */
FOUNDATION_EXPORT FBSDKAppEventParameterName FBSDKAppEventParameterNameNumItems;

/** Parameter key used to specify whether payment info is available for the `FBAppEventNameInitiatedCheckout` event.  `FBSDKAppEventParameterValueYes` and `FBSDKAppEventParameterValueNo` are good canonical values to use for this parameter. */
FOUNDATION_EXPORT FBSDKAppEventParameterName FBSDKAppEventParameterNamePaymentInfoAvailable;

/** Parameter key used to specify method user has used to register for the app, e.g., "Facebook", "email", "Twitter", etc */
FOUNDATION_EXPORT FBSDKAppEventParameterName FBSDKAppEventParameterNameRegistrationMethod;

/** Parameter key used to specify the string provided by the user for a search operation. */
FOUNDATION_EXPORT FBSDKAppEventParameterName FBSDKAppEventParameterNameSearchString;

/** Parameter key used to specify whether the activity being logged about was successful or not.  `FBSDKAppEventParameterValueYes` and `FBSDKAppEventParameterValueNo` are good canonical values to use for this parameter. */
FOUNDATION_EXPORT FBSDKAppEventParameterName FBSDKAppEventParameterNameSuccess;
