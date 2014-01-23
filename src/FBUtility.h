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

@class FBRequest;
@class FBSession;

@protocol FBGraphObject;

typedef enum FBAdvertisingTrackingStatus {
    AdvertisingTrackingAllowed,
    AdvertisingTrackingDisallowed,
    AdvertisingTrackingUnspecified
} FBAdvertisingTrackingStatus;

@interface FBUtility : NSObject

+ (NSDictionary*)queryParamsDictionaryFromFBURL:(NSURL*)url;
+ (NSDictionary*)dictionaryByParsingURLQueryPart:(NSString *)encodedString;
+ (NSString *)stringBySerializingQueryParameters:(NSDictionary *)queryParameters;
+ (NSString *)stringByURLDecodingString:(NSString*)escapedString;
+ (NSString*)stringByURLEncodingString:(NSString*)unescapedString;
+ (id<FBGraphObject>)graphObjectInArray:(NSArray*)array withSameIDAs:(id<FBGraphObject>)item;

+ (unsigned long)currentTimeInMilliseconds;
+ (NSTimeInterval)randomTimeInterval:(NSTimeInterval)minValue withMaxValue:(NSTimeInterval)maxValue;
+ (void)centerView:(UIView*)view tableView:(UITableView*)tableView;
+ (NSString *)stringFBIDFromObject:(id)object;
+ (NSString *)stringAppBaseUrlFromAppId:(NSString *)appID urlSchemeSuffix:(NSString *)urlSchemeSuffix;
+ (NSDate*)expirationDateFromExpirationTimeIntervalString:(NSString*)expirationTime;
+ (NSDate*)expirationDateFromExpirationUnixTimeString:(NSString*)expirationTime;
+ (NSBundle *)facebookSDKBundle;
+ (NSString *)localizedStringForKey:(NSString *)key
                        withDefault:(NSString *)value;
+ (NSString *)localizedStringForKey:(NSString *)key
                        withDefault:(NSString *)value
                           inBundle:(NSBundle *)bundle;
// Returns YES when the bundle identifier is for one of the native facebook apps
+ (BOOL)isFacebookBundleIdentifier:(NSString *)bundleIdentifier;

+ (BOOL)isPublishPermission:(NSString*)permission;
+ (BOOL)areAllPermissionsReadPermissions:(NSArray*)permissions;
+ (NSArray*)addBasicInfoPermission:(NSArray*)permissions;
+ (void)fetchAppSettings:(NSString *)appID
                callback:(void (^)(FBFetchedAppSettings *, NSError *))callback;
// Only returns nil if no settings have been fetched; otherwise it returns the last fetched settings.
// If the settings are stale, an async request will be issued to fetch them.
+ (FBFetchedAppSettings *)fetchedAppSettings;
+ (NSString *)attributionID;
+ (NSString *)advertiserID;
+ (FBAdvertisingTrackingStatus)advertisingTrackingStatus;
+ (void)updateParametersWithEventUsageLimitsAndBundleInfo:(NSMutableDictionary *)parameters;

// Encode a data structure in JSON, any errors will just be logged.
+ (NSString *)simpleJSONEncode:(id)data;
+ (id)simpleJSONDecode:(NSString *)jsonEncoding;
+ (NSString *)simpleJSONEncode:(id)data
                         error:(NSError **)error
                writingOptions:(NSJSONWritingOptions)writingOptions;
+ (id)simpleJSONDecode:(NSString *)jsonEncoding
                 error:(NSError **)error;
+ (BOOL) isRetinaDisplay;
+ (NSString *)newUUIDString;
+ (BOOL)isRegisteredURLScheme:(NSString *)urlScheme;

+ (NSString *) buildFacebookUrlWithPre:(NSString*)pre;
+ (NSString *) buildFacebookUrlWithPre:(NSString*)pre
                              withPost:(NSString *)post;
+ (BOOL)isMultitaskingSupported;
+ (BOOL)isSystemAccountStoreAvailable;
+ (void)deleteFacebookCookies;
+ (NSString *)dialogBaseURL;

@end

#define FBConditionalLog(condition, desc, ...) \
do { \
    if (!(condition)) { \
        NSString *msg = [NSString stringWithFormat:(desc), ##__VA_ARGS__]; \
        NSLog(@"FBConditionalLog: %@", msg); \
    } \
} while(NO)

#define FB_BASE_URL @"facebook.com"
