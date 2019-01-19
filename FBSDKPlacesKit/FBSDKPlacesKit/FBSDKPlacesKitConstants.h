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

NS_ASSUME_NONNULL_BEGIN

/**
 The level of confidence the Facebook SDK has that a Place is the correct one for the
 user's current location.

 - FBSDKPlaceLocationConfidenceNotApplicable: Used to indicate that any level is
 acceptable as a minimum threshold
 - FBSDKPlaceLocationConfidenceLow: Low confidence level.
 - FBSDKPlaceLocationConfidenceMedium: Medium confidence level.
 - FBSDKPlaceLocationConfidenceHigh: High confidence level.
 */
typedef NS_ENUM(NSInteger, FBSDKPlaceLocationConfidence) {
  FBSDKPlaceLocationConfidenceNotApplicable,
  FBSDKPlaceLocationConfidenceLow,
  FBSDKPlaceLocationConfidenceMedium,
  FBSDKPlaceLocationConfidenceHigh
} NS_SWIFT_NAME(PlaceLocationConfidence);

/**
 These are the fields currently exposed by FBSDKPlacesKit. They map to the fields on
 Place objects returned by the Graph API, which can be found
 [here](https://developers.facebook.com/docs/places ). Should fields be added to the Graph API in
 the future, you can use strings found in the online documenation in addition to
 these string constants.
 */

/// typedef for FBSDKPlacesCategoryKey
typedef NSString *const FBSDKPlacesCategoryKey NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(PlacesCategoryKey);

/// typedef for FBSDKPlacesFieldKey
typedef NSString *const FBSDKPlacesFieldKey NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(PlacesFieldKey);

/// typedef for FBSDKPlacesResponseKey
typedef NSString *const FBSDKPlacesResponseKey NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(PlacesResponseKey);

/// typedef for FBSDKPlacesParameterKey
typedef NSString *const FBSDKPlacesParameterKey NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(PlacesParameterKey);

/// typedef for FBSDKPlacesSummaryKey
typedef NSString *const FBSDKPlacesSummaryKey NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(PlacesSummaryKey);

/**
 Field Key for information about the Place.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyAbout;

/**
 Field Key for AppLinks for the Place.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyAppLinks;

/**
 Field Key for the Place's categories.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyCategories;

/**
 Field Key for the number of checkins at the Place.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyCheckins;

/**
 Field Key for the confidence level for a current place estimate candidate.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyConfidence;

/**
 Field Key for the Place's cover photo. Note that this is not the actual photo data,
 but rather URLs and other metadata.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyCoverPhoto;

/**
 Field Key for the description of the Place.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyDescription;

/**
 Field Key for the social sentence and like count information for this place. This is
 the same information used for the Like button.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyEngagement;

/**
 Field Key for hour ranges for when the Place is open. Each day can have two different
 hours ranges. The keys in the dictionary are in the form of {day}_{number}_{status}.
 {day} should be the first 3 characters of the day of the week, {number} should be
 either 1 or 2 to allow for the two different hours ranges per day. {status} should be
 either open or close, to delineate the start or end of a time range. An example would
 be mon_1_open with value 17:00 and mon_1_close with value 21:15 which would represent
 a single opening range of 5 PM to 9:15 PM on Mondays. You can find an example of hours
 being parsed out in the Sample App.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyHours;

/**
 Field Key for a value indicating whether this place is always open.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyIsAlwaysOpen;

/**
 Field Key for a value indicating whether this place is permanently closed.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyIsPermanentlyClosed;

/**
 Pages with a large number of followers can be manually verified by Facebook as having an
 authentic identity. This field indicates whether the page is verified by this process.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyIsVerified;

/**
 Field Key for address and latitude/longitude information for the place.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyLocation;

/**
 Field Key for a link to Place's Facebook page.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyLink;

/**
 Field Key for the name of the place.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyName;

/**
 Field Key for the overall page rating based on rating surveys from users on a scale
 from 1-5. This value is normalized, and is not guaranteed to be a strict average of
 user ratings.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyOverallStarRating;

/**
 Field Key for the Facebook Page information.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyPage;

/**
 Field Key for PageParking information for the Place.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyParking;

/**
 Field Key for available payment options.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyPaymentOptions;

/**
 Field Key for the unique Facebook ID of the place.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyPlaceID;

/**
 Field Key for the Place's phone number.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyPhone;

/**
 Field Key for the Place's photos. Note that this is not the actual photo data, but
 rather URLs and other metadata.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyPhotos;

/**
 Field Key for the price range of the business, expressed as a string. Applicable to
 Restaurants or Nightlife. Can be one of $ (0-10), $$ (10-30), $$$ (30-50), $$$$ (50+),
 or Unspecified.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyPriceRange;

/**
 Field Key for the Place's profile photo. Note that this is not the actual photo data,
 but rather URLs and other metadata.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyProfilePhoto;

/**
 Field Key for the number of ratings for the place.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyRatingCount;

/**
 Field Key for restaurant services e.g: delivery, takeout.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyRestaurantServices;

/**
 Field Key for restaurant specialties.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyRestaurantSpecialties;

/**
 Field Key for the address in a single line.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeySingleLineAddress;

/**
 Field Key for the string of the Place's website URL.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyWebsite;

/**
 Field Key for the Workflows.
 */
FOUNDATION_EXPORT FBSDKPlacesFieldKey FBSDKPlacesFieldKeyWorkflows;

/**
 Response Key for the place's city field.
 */
FOUNDATION_EXPORT FBSDKPlacesResponseKey FBSDKPlacesResponseKeyCity;

/**
 Response Key for the place's city ID field.
 */
FOUNDATION_EXPORT FBSDKPlacesResponseKey FBSDKPlacesResponseKeyCityID;

/**
 Response Key for the place's country field.
 */
FOUNDATION_EXPORT FBSDKPlacesResponseKey FBSDKPlacesResponseKeyCountry;

/**
 Response Key for the place's country code field.
 */
FOUNDATION_EXPORT FBSDKPlacesResponseKey FBSDKPlacesResponseKeyCountryCode;

/**
 Response Key for the place's latitude field.
 */
FOUNDATION_EXPORT FBSDKPlacesResponseKey FBSDKPlacesResponseKeyLatitude;

/**
 Response Key for the place's longitude field.
 */
FOUNDATION_EXPORT FBSDKPlacesResponseKey FBSDKPlacesResponseKeyLongitude;

/**
 Response Key for the place's region field.
 */
FOUNDATION_EXPORT FBSDKPlacesResponseKey FBSDKPlacesResponseKeyRegion;

/**
 Response Key for the place's region ID field.
 */
FOUNDATION_EXPORT FBSDKPlacesResponseKey FBSDKPlacesResponseKeyRegionID;

/**
 Response Key for the place's state field.
 */
FOUNDATION_EXPORT FBSDKPlacesResponseKey FBSDKPlacesResponseKeyState;

/**
 Response Key for the place's street field.
 */
FOUNDATION_EXPORT FBSDKPlacesResponseKey FBSDKPlacesResponseKeyStreet;

/**
 Response Key for the place's zip code field.
 */
FOUNDATION_EXPORT FBSDKPlacesResponseKey FBSDKPlacesResponseKeyZip;

/**
 Response Key for the categories that this place matched.
 To be used on the search request if the categories parameter is specified.
 */
FOUNDATION_EXPORT FBSDKPlacesResponseKey FBSDKPlacesResponseKeyMatchedCategories;

/**
 Response Key for the photo source dictionary.
 */
FOUNDATION_EXPORT FBSDKPlacesResponseKey FBSDKPlacesResponseKeyPhotoSource;

/**
 Response Key for response data.
 */
FOUNDATION_EXPORT FBSDKPlacesResponseKey FBSDKPlacesResponseKeyData;

/**
 Response Key for a URL.
 */
FOUNDATION_EXPORT FBSDKPlacesResponseKey FBSDKPlacesResponseKeyUrl;

/**
 Parameter Key for the current place summary.
 */
FOUNDATION_EXPORT FBSDKPlacesParameterKey FBSDKPlacesParameterKeySummary;

/**
 Summary Key for the current place tracking ID.
 */
FOUNDATION_EXPORT FBSDKPlacesSummaryKey FBSDKPlacesSummaryKeyTracking;

NS_ASSUME_NONNULL_END
