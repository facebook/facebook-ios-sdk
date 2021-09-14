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

#import "FBSDKAppEventsCAPITransformer.h"

#import <Foundation/Foundation.h>

#import "FBSDKSettings+Internal.h"
#import "FBSDKTimeSpentData.h"

// App events user data fields
static FBSDKAppEventUserDataType FBSDKAppEventsUserDataAnonId = @"anon_id";
static FBSDKAppEventUserDataType FBSDKAppEventsUserDataAppUserId = @"app_user_id";
static FBSDKAppEventUserDataType FBSDKAppEventsUserDataAdvertiserId = @"advertiser_id";
static FBSDKAppEventUserDataType FBSDKAppEventsUserDataPageId = @"page_id";
static FBSDKAppEventUserDataType FBSDKAppEventsUserDataPageScopedUserId = @"page_scoped_user_id";
FBSDKAppEventUserDataType FBSDKAppEventsUserDataSection = @"ud";

// App events app data fields
static FBSDKAppEventUserDataType FBSDKAppEventsAppDataAdvTE = @"advertiser_tracking_enabled";
static FBSDKAppEventUserDataType FBSDKAppEventsAppDataAppTE = @"application_tracking_enabled";
static FBSDKAppEventUserDataType FBSDKAppEventsAppDataConsiderViews = @"consider_views";
static FBSDKAppEventUserDataType FBSDKAppEventsAppDataDeviceToken = @"device_token";
static FBSDKAppEventUserDataType FBSDKAppEventsAppDataExtInfo = @"extinfo";
static FBSDKAppEventUserDataType FBSDKAppEventsAppDataIncludeDwellData = @"include_dwell_data";
static FBSDKAppEventUserDataType FBSDKAppEventsAppDataIncludeVideoData = @"include_video_data";
static FBSDKAppEventUserDataType FBSDKAppEventsAppDataInstallReferrer = @"install_referrer";
static FBSDKAppEventUserDataType FBSDKAppEventsAppDataInstallerPackage = @"installer_package";
static FBSDKAppEventUserDataType FBSDKAppEventsAppDataReceiptData = @"receipt_data";
static FBSDKAppEventUserDataType FBSDKAppEventsAppDataUrlSchemes = @"url_schemes";

// App events custom events fields
static NSString *const FBSDKAppEventsCustomEventsValue = @"_valueToSum";

// CAPI endpoint data mapping sections
static NSString *const FBSDKAppEventsCAPITxUserData = @"user_data";
static NSString *const FBSDKAppEventsCAPITxAppData = @"app_data";
static NSString *const FBSDKAppEventsCAPITxCustomData = @"custom_data";

static NSDictionary<NSString *, NSArray<NSString *> *> *topLevelTransformations, *customEventTransformations;
static NSDictionary<NSString *, NSString *> *standardEventTransformations;
static NSSet<NSString *> *copyTheseParameters;

@implementation FBSDKAppEventsCAPITransformer

+ (void)initialize
{
  topLevelTransformations =
  @{
    // user_data mapping
    FBSDKAppEventsUserDataAnonId : @[FBSDKAppEventsCAPITxUserData, FBSDKAppEventsUserDataAnonId],
    FBSDKAppEventsUserDataAppUserId : @[FBSDKAppEventsCAPITxUserData, @"fb_login_id"],
    FBSDKAppEventsUserDataAdvertiserId : @[FBSDKAppEventsCAPITxUserData, @"madid"],
    FBSDKAppEventsUserDataPageId : @[FBSDKAppEventsCAPITxUserData, FBSDKAppEventsUserDataPageId],
    FBSDKAppEventsUserDataPageScopedUserId : @[FBSDKAppEventsCAPITxUserData, FBSDKAppEventsUserDataPageScopedUserId],
    FBSDKAppEventsUserDataSection : @[FBSDKAppEventsCAPITxUserData],

    // app_data mapping
    FBSDKAppEventsAppDataAdvTE : @[FBSDKAppEventsCAPITxAppData, FBSDKAppEventsAppDataAdvTE],
    FBSDKAppEventsAppDataAppTE : @[FBSDKAppEventsCAPITxAppData, FBSDKAppEventsAppDataAppTE],
    FBSDKAppEventsAppDataConsiderViews : @[FBSDKAppEventsCAPITxAppData, FBSDKAppEventsAppDataConsiderViews],
    FBSDKAppEventsAppDataDeviceToken : @[FBSDKAppEventsCAPITxAppData, FBSDKAppEventsAppDataDeviceToken],
    FBSDKAppEventsAppDataExtInfo : @[FBSDKAppEventsCAPITxAppData, FBSDKAppEventsAppDataExtInfo],
    FBSDKAppEventsAppDataIncludeDwellData : @[FBSDKAppEventsCAPITxAppData, FBSDKAppEventsAppDataIncludeDwellData],
    FBSDKAppEventsAppDataIncludeVideoData : @[FBSDKAppEventsCAPITxAppData, FBSDKAppEventsAppDataIncludeVideoData],
    FBSDKAppEventsAppDataInstallReferrer : @[FBSDKAppEventsCAPITxAppData, FBSDKAppEventsAppDataInstallReferrer],
    FBSDKAppEventsAppDataInstallerPackage : @[FBSDKAppEventsCAPITxAppData, FBSDKAppEventsAppDataInstallerPackage],
    FBSDKAppEventsAppDataReceiptData : @[FBSDKAppEventsCAPITxAppData, FBSDKAppEventsAppDataReceiptData],
    FBSDKAppEventsAppDataUrlSchemes : @[FBSDKAppEventsCAPITxAppData, FBSDKAppEventsAppDataUrlSchemes],
  };

  customEventTransformations =
  @{
    // custom_events mapping
    FBSDKAppEventParameterLogTime : @[@"event_time"],
    FBSDKAppEventParameterEventName : @[@"event_name"],
    FBSDKAppEventsCustomEventsValue : @[FBSDKAppEventsCAPITxCustomData, @"value"],
    FBSDKAppEventParameterNameContentID : @[FBSDKAppEventsCAPITxCustomData, @"content_ids"], // string to array conversion required
    FBSDKAppEventParameterNameContent : @[FBSDKAppEventsCAPITxCustomData, @"contents"], // string to array conversion required, contents has an extra field: price
    FBSDKAppEventParameterNameContentType : @[FBSDKAppEventsCAPITxCustomData, @"content_type"],
    FBSDKAppEventParameterNameCurrency : @[FBSDKAppEventsCAPITxCustomData, @"currency"],
    FBSDKAppEventParameterNameDescription : @[FBSDKAppEventsCAPITxCustomData, @"description"],
    FBSDKAppEventParameterNameLevel : @[FBSDKAppEventsCAPITxCustomData, @"level"],
    FBSDKAppEventParameterNameMaxRatingValue : @[FBSDKAppEventsCAPITxCustomData, @"max_rating_value"],
    FBSDKAppEventParameterNameNumItems : @[FBSDKAppEventsCAPITxCustomData, @"num_items"],
    FBSDKAppEventParameterNamePaymentInfoAvailable : @[FBSDKAppEventsCAPITxCustomData, @"payment_info_available"],
    FBSDKAppEventParameterNameRegistrationMethod : @[FBSDKAppEventsCAPITxCustomData, @"registration_method"],
    FBSDKAppEventParameterNameSearchString : @[FBSDKAppEventsCAPITxCustomData, @"search_string"],
    FBSDKAppEventParameterNameSuccess : @[FBSDKAppEventsCAPITxCustomData, @"success"],
    FBSDKAppEventParameterNameOrderID : @[FBSDKAppEventsCAPITxCustomData, @"order_id"],
    FBSDKAppEventParameterNameAdType : @[FBSDKAppEventsCAPITxCustomData, @"ad_type"],
  };

  standardEventTransformations =
  @{
    FBSDKAppEventNameUnlockedAchievement : @"AchievementUnlocked",
    FBSDKAppEventNameActivatedApp : @"ActivateApp",
    FBSDKAppEventNameAddedPaymentInfo : @"AddPaymentInfo",
    FBSDKAppEventNameAddedToCart : @"AddToCart",
    FBSDKAppEventNameAddedToWishlist : @"AddToWishlist",
    FBSDKAppEventNameCompletedRegistration : @"CompleteRegistration",
    FBSDKAppEventNameViewedContent : @"ViewContent",
    FBSDKAppEventNameInitiatedCheckout : @"InitiateCheckout",
    FBSDKAppEventNameAchievedLevel : @"LevelAchieved",
    FBSDKAppEventNamePurchased : @"Purchase",
    FBSDKAppEventNameRated : @"Rate",
    FBSDKAppEventNameSearched : @"Search",
    FBSDKAppEventNameSpentCredits : @"SpentCredits",
    FBSDKAppEventNameCompletedTutorial : @"TutorialCompletion",
  };

  copyTheseParameters =
  [NSSet setWithArray:@[
    DATA_PROCESSING_OPTIONS,
    DATA_PROCESSING_OPTIONS_COUNTRY,
    DATA_PROCESSING_OPTIONS_STATE,
   ]];
}

#if DEBUG && FBTEST
+ (NSDictionary<NSString *, NSArray<NSString *> *> *)topLevelTransformations
{
  return topLevelTransformations;
}

+ (NSDictionary<NSString *, NSArray<NSString *> *> *)customEventTransformations
{
  return customEventTransformations;
}

#endif

@end
