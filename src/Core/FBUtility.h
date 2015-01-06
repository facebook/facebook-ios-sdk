/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "FBFetchedAppSettings.h"
#import "FBLogger.h"
#import "FBSDKMacros.h"

@class FBRequest;
@class FBSession;

@protocol FBGraphObject;

typedef NS_ENUM(NSUInteger, FBAdvertisingTrackingStatus) {
    AdvertisingTrackingAllowed,
    AdvertisingTrackingDisallowed,
    AdvertisingTrackingUnspecified
};

typedef NS_ENUM(NSInteger, FBIOSVersion) {
  FBIOSVersion_6_0,
  FBIOSVersion_6_1,
  FBIOSVersion_7_0,
  FBIOSVersion_7_1,
  FBIOSVersion_8_0,

  FBIOSVersionCount
};

typedef NS_ENUM(NSUInteger, FBTriStateBOOL) {
    FBTriStateBOOLValueNO = 0,
    FBTriStateBOOLValueYES,
    FBTriStateBOOLValueUnknown
};

FBSDK_EXTERN FBTriStateBOOL FBTriStateBOOLFromBOOL(BOOL value);
FBSDK_EXTERN BOOL BOOLFromFBTriStateBOOL(FBTriStateBOOL value, BOOL defaultValue);

FBSDK_EXTERN BOOL FBCheckObjectIsEqual(NSObject *a, NSObject *b);

@interface FBUtility : NSObject

#pragma mark Object Helpers

+ (id<FBGraphObject>)graphObjectInArray:(NSArray *)array withSameIDAs:(id<FBGraphObject>)item;
+ (NSString *)stringFBIDFromObject:(id)object;

#pragma mark - UI Helpers

+ (void)centerView:(UIView *)view tableView:(UITableView *)tableView;

#pragma mark - Time Data

+ (unsigned long)currentTimeInMilliseconds;
+ (NSTimeInterval)randomTimeInterval:(NSTimeInterval)minValue withMaxValue:(NSTimeInterval)maxValue;
+ (NSDate *)expirationDateFromExpirationTimeIntervalString:(NSString *)expirationTime;
+ (NSDate *)expirationDateFromExpirationUnixTimeString:(NSString *)expirationTime;

#pragma mark - Localized strings

+ (NSString *)localizedStringForKey:(NSString *)key
                        withDefault:(NSString *)value;
+ (NSString *)localizedStringForKey:(NSString *)key
                        withDefault:(NSString *)value
                           inBundle:(NSBundle *)bundle;

#pragma mark - Bundle

+ (NSBundle *)facebookSDKBundle;
// Returns YES when the bundle identifier is for one of the native facebook apps
+ (BOOL)isFacebookBundleIdentifier:(NSString *)bundleIdentifier;
+ (BOOL)isSafariBundleIdentifier:(NSString *)bundleIdentifier;

#pragma mark - Permissions

+ (BOOL)isPublishPermission:(NSString *)permission;
+ (BOOL)areAllPermissionsReadPermissions:(NSArray *)permissions;
+ (void)addBasicInfoPermission:(NSMutableArray *)permissions;

#pragma mark - App Settings

+ (void)fetchAppSettings:(NSString *)appID
                callback:(void (^)(FBFetchedAppSettings *, NSError *))callback;
// Only returns nil if no settings have been fetched; otherwise it returns the last fetched settings.
// If the settings are stale, an async request will be issued to fetch them.
+ (FBFetchedAppSettings *)fetchedAppSettings;

#pragma mark - IDs / Attribution

+ (NSString *)newUUIDString;
+ (NSString *)attributionID;
+ (NSString *)advertiserID;
+ (NSString *)anonymousID;
+ (FBAdvertisingTrackingStatus)advertisingTrackingStatus;
+ (NSMutableDictionary<FBGraphObject> *)activityParametersDictionaryForEvent:(NSString *)eventCategory
                                                          implicitEventsOnly:(BOOL)implicitEventsOnly
                                                   shouldAccessAdvertisingID:(BOOL)shouldAccessAdvertisingID;

#pragma mark - JSON Encode / Decode

// Encode a data structure in JSON, any errors will just be logged.
+ (NSString *)simpleJSONEncode:(id)data;
+ (id)simpleJSONDecode:(NSString *)jsonEncoding;
+ (NSString *)simpleJSONEncode:(id)data
                         error:(NSError **)error
                writingOptions:(NSJSONWritingOptions)writingOptions;
+ (id)simpleJSONDecode:(NSString *)jsonEncoding
                 error:(NSError **)error;

#pragma mark - URLs Params Encode / Decode

+ (NSDictionary *)queryParamsDictionaryFromFBURL:(NSURL *)url;
+ (NSDictionary *)dictionaryByParsingURLQueryPart:(NSString *)encodedString;
+ (NSString *)stringBySerializingQueryParameters:(NSDictionary *)queryParameters;
+ (NSString *)stringByURLDecodingString:(NSString *)escapedString;
+ (NSString *)stringByURLEncodingString:(NSString *)unescapedString;

#pragma mark - URLs Builder

+ (NSString *)stringAppBaseUrlFromAppId:(NSString *)appID urlSchemeSuffix:(NSString *)urlSchemeSuffix;
+ (NSString *)buildFacebookUrlWithPre:(NSString *)pre;
+ (NSString *)buildFacebookUrlWithPre:(NSString *)pre
                             withPost:(NSString *)post;
+ (NSString *)buildFacebookUrlWithPre:(NSString *)pre
                                 post:(NSString *)post
                              version:(NSString *)version;
+ (NSString *)dialogBaseURL;

#pragma mark - System Info

+ (BOOL)isRetinaDisplay;
+ (BOOL)isRegisteredURLScheme:(NSString *)urlScheme;
+ (BOOL)isMultitaskingSupported;
+ (BOOL)isUIKitLinkedOnOrAfter:(FBIOSVersion)version;
+ (BOOL)isRunningOnOrAfter:(FBIOSVersion)version;
+ (BOOL)isSystemAccountStoreAvailable;

#pragma mark - Cookies

+ (void)deleteFacebookCookies;

@end

#define FBConditionalLog(condition, loggingBehavior, desc, ...) \
do { \
    if (!(condition)) { \
        NSString *msg = [NSString stringWithFormat:(desc), ##__VA_ARGS__]; \
        [FBLogger singleShotLogEntry:loggingBehavior logEntry:msg]; \
    } \
} while(NO)

#define FB_BASE_URL @"facebook.com"
