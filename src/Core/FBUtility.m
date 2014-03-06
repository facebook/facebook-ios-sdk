/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0

 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBAppEvents.h"
#import "FBUtility.h"
#import "FBGraphObject.h"
#import "FBLogger.h"
#import "FBRequest+Internal.h"
#import "FBSession.h"
#import "FBDynamicFrameworkLoader.h"
#import "FBSettings+Internal.h"

#import <AdSupport/AdSupport.h>
#include <sys/time.h>

static const double APPSETTINGS_STALE_THRESHOLD_SECONDS = 60 * 60; // one hour.
static FBFetchedAppSettings *g_fetchedAppSettings = nil;
static NSError *g_fetchedAppSettingsError = nil;
static NSDate *g_fetchedAppSettingsTimestamp = nil;

@implementation FBUtility

+ (NSDictionary *)queryParamsDictionaryFromFBURL:(NSURL *)url {
    // version 3.2.3 of the Facebook app encodes the parameters in the query but
    // version 3.3 and above encode the parameters in the fragment;
    // merge them together with fragment taking priority.

    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if ([url query]) {
        [result addEntriesFromDictionary:[FBUtility dictionaryByParsingURLQueryPart:[url query]]];
    }
    if ([url fragment]) {
        [result addEntriesFromDictionary:[FBUtility dictionaryByParsingURLQueryPart:[url fragment]]];
    }

    return result;
}

// finishes the parsing job that NSURL starts
+ (NSDictionary *)dictionaryByParsingURLQueryPart:(NSString *)encodedString {

    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSArray *parts = [encodedString componentsSeparatedByString:@"&"];

    for (NSString *part in parts) {
        if ([part length] == 0) {
            continue;
        }

        NSRange index = [part rangeOfString:@"="];
        NSString *key;
        NSString *value;

        if (index.location == NSNotFound) {
            key = part;
            value = @"";
        } else {
            key = [part substringToIndex:index.location];
            value = [part substringFromIndex:index.location + index.length];
        }

        if (key && value) {
            [result setObject:[FBUtility stringByURLDecodingString:value]
                       forKey:[FBUtility stringByURLDecodingString:key]];
        }
    }
    return result;
}

+ (NSString *)stringBySerializingQueryParameters:(NSDictionary *)queryParameters {
    NSMutableString *queryString = [[[NSMutableString alloc] init] autorelease];
    BOOL hasParameters = NO;
    if (queryParameters) {
        for (NSString *key in queryParameters) {
            if (hasParameters) {
                [queryString appendString:@"&"];
            }
            id value = queryParameters[key];
            if ([value isKindOfClass:[NSString class]]) {
                value = [FBUtility stringByURLEncodingString:value];
            }
            [queryString appendFormat:@"%@=%@", key, value];
            hasParameters = YES;
        }
    }

    return [[queryString copy] autorelease];
}

// the reverse of url encoding
+ (NSString *)stringByURLDecodingString:(NSString *)escapedString {
    return [[escapedString stringByReplacingOccurrencesOfString:@"+" withString:@" "]
            stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)stringByURLEncodingString:(NSString *)unescapedString {
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                           kCFAllocatorDefault,
                                                                           (CFStringRef)unescapedString,
                                                                           NULL, // characters to leave unescaped
                                                                           (CFStringRef)@":!*();@/&?#[]+$,='%’\"",
                                                                           kCFStringEncodingUTF8);
    [result autorelease];
    return result;
}

+ (unsigned long)currentTimeInMilliseconds {
    struct timeval time;
    gettimeofday(&time, NULL);
    return (time.tv_sec * 1000) + (time.tv_usec / 1000);
}

+ (NSTimeInterval)randomTimeInterval:(NSTimeInterval)minValue withMaxValue:(NSTimeInterval)maxValue {
    return minValue + (maxValue - minValue) * (double)arc4random() / UINT32_MAX;
}

+ (id<FBGraphObject>)graphObjectInArray:(NSArray *)array withSameIDAs:(id<FBGraphObject>)item {
    for (id<FBGraphObject> obj in array) {
        if ([FBGraphObject isGraphObjectID:obj sameAs:item]) {
            return obj;
        }
    }
    return nil;
}

// The assumption here is that the view and the tableView share a common parent.
+ (void)centerView:(UIView *)view tableView:(UITableView *)tableView {
    // We want to center the view in the table  as much as possible, but we also want to center it
    // within a cell so it is visually appealing.
    CGRect bounds = tableView.bounds;
    CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));

    CGFloat rowHeight = tableView.rowHeight;
    int numRows = bounds.size.height / rowHeight;
    int centerRow = numRows / 2;
    center.y = rowHeight * centerRow + rowHeight / 2;

    center = [view.superview convertPoint:center fromView:tableView];
    view.center = center;
}

+ (NSString *)stringFBIDFromObject:(id)object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        id val = [object objectForKey:@"id"];
        if ([val isKindOfClass:[NSString class]]) {
            return val;
        }
    }
    return [object description];
}

+ (NSString *)stringAppBaseUrlFromAppId:(NSString *)appID urlSchemeSuffix:(NSString *)urlSchemeSuffix {
    return [NSString stringWithFormat:@"fb%@%@://authorize",
            appID ?: @"",
            urlSchemeSuffix ?: @""];
}

+ (NSDate *)expirationDateFromExpirationUnixTimeString:(NSString *)expirationTime {
    NSDate *expirationDate = nil;
    if (expirationTime != nil) {
        NSTimeInterval expValue = [expirationTime doubleValue];
        if (expValue != 0) {
            expirationDate = [NSDate dateWithTimeIntervalSince1970:expValue];
        }
    }
    return expirationDate;
}

+ (NSDate *)expirationDateFromExpirationTimeIntervalString:(NSString *)expirationTime {
    NSDate *expirationDate = nil;
    if (expirationTime != nil) {
        int expValue = [expirationTime intValue];
        if (expValue != 0) {
            expirationDate = [NSDate dateWithTimeIntervalSinceNow:expValue];
        }
    }
    return expirationDate;
}

+ (NSBundle *)facebookSDKBundle {
    static dispatch_once_t fetchBundleOnce;
    static NSBundle *bundle = nil;

    dispatch_once(&fetchBundleOnce, ^{
        NSString *path = [[NSBundle mainBundle] pathForResource:[FBSettings resourceBundleName]
                                                         ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:path];
    });
    return bundle;
}

+ (NSString *)localizedStringForKey:(NSString *)key
                        withDefault:(NSString *)value {
    return [self localizedStringForKey:key withDefault:value inBundle:FBUtility.facebookSDKBundle];
}

+ (NSString *)localizedStringForKey:(NSString *)key
                        withDefault:(NSString *)value
                           inBundle:(NSBundle *)bundle {
    NSString *result = value;
    if (bundle) {
        result = [bundle localizedStringForKey:key
                                         value:value
                                         table:nil];
    }
    return result;
}

+ (BOOL)isFacebookBundleIdentifier:(NSString *)bundleIdentifier {
    return [bundleIdentifier hasPrefix:@"com.facebook."] ||
           [bundleIdentifier hasPrefix:@".com.facebook."];
}

#pragma mark - permissions related

+ (BOOL)isPublishPermission:(NSString *)permission {
    return [permission hasPrefix:@"publish"] ||
    [permission hasPrefix:@"manage"] ||
    [permission isEqualToString:@"ads_management"] ||
    [permission isEqualToString:@"create_event"] ||
    [permission isEqualToString:@"rsvp_event"];
}

+ (BOOL)areAllPermissionsReadPermissions:(NSArray *)permissions {
    for (NSString *permission in permissions) {
        if ([self isPublishPermission:permission]) {
            return NO;
        }
    }
    return YES;
}

+ (NSArray *)addBasicInfoPermission:(NSArray *)permissions {
    // When specifying read permissions, be sure basic info is included; "email" is used
    // as a proxy for basic info permission.
    for (NSString *p in permissions) {
        if ([p isEqualToString:@"email"]) {
            // Already requested, don't need to add it again.
            return permissions;
        }
    }

    NSMutableArray *newPermissions = [NSMutableArray arrayWithArray:permissions];
    [newPermissions addObject:@"email"];
    return newPermissions;
}

// Make a call to the Graph API to get a variety of data for the app, and on completion, invoke the callback with
// the result.  Cache the result for subsequent invocations.  Expect only to ever be called with one appID.  Results
// with calling with a second appid are undefined (in reality will just return the previously requested app's results).

+ (void)fetchAppSettings:(NSString *)appID
                callback:(void (^)(FBFetchedAppSettings *, NSError *))callback {
    if ([FBUtility isFetchedFBAppSettingsStale] || (!g_fetchedAppSettingsError && !g_fetchedAppSettings)) {

        NSString *pingPath = [NSString stringWithFormat:@"%@?fields=supports_attribution,supports_implicit_sdk_logging,suppress_native_ios_gdp,name", appID, nil];
        FBRequest *pingRequest = [[[FBRequest alloc] initWithSession:nil graphPath:pingPath] autorelease];
        pingRequest.canCloseSessionOnError = NO;
        [pingRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            [g_fetchedAppSettingsError release];
            g_fetchedAppSettingsError = nil;

            if (error) {
                if (g_fetchedAppSettings) {
                    // We have older app settings but the refresh received an error.
                    // Log and ignore the error.
                    [FBLogger singleShotLogEntry:FBLoggingBehaviorInformational formatString:@"fetchAppSettings refresh failed with %@", error];
                } else {
                    // Only set the error if we don't have previously fetched app settings.
                    // (i.e., if we have app settings and a new call gets an error, we'll
                    // ignore the error and surface the last successfully fetched settings).
                    g_fetchedAppSettingsError = error;
                    [g_fetchedAppSettingsError retain];
                }
            } else {
                if ([result respondsToSelector:@selector(objectForKey:)]) {
                    [g_fetchedAppSettingsTimestamp release];
                    [g_fetchedAppSettings release];

                    g_fetchedAppSettings = [[FBFetchedAppSettings alloc] initWithAppID:appID];
                    g_fetchedAppSettingsTimestamp = [[NSDate date] retain];

                    g_fetchedAppSettings.serverAppName = [result objectForKey:@"name"];
                    g_fetchedAppSettings.supportsAttribution = [[result objectForKey:@"supports_attribution"] boolValue];
                    g_fetchedAppSettings.supportsImplicitSdkLogging = [[result objectForKey:@"supports_implicit_sdk_logging"] boolValue];
                    g_fetchedAppSettings.suppressNativeGdp = [[result objectForKey:@"suppress_native_ios_gdp"] boolValue];
                }
            }
            [FBUtility callTheFetchAppSettingsCallback:callback];
        }];
    } else {
        [FBUtility callTheFetchAppSettingsCallback:callback];
    }
}

+ (FBFetchedAppSettings *)fetchedAppSettings {
    if ([FBUtility isFetchedFBAppSettingsStale]) {
        [FBUtility fetchAppSettings:g_fetchedAppSettings.appID callback:nil];
    }
    return g_fetchedAppSettings;
}

+ (BOOL)isFetchedFBAppSettingsStale {
    return g_fetchedAppSettingsTimestamp && ([[NSDate date] timeIntervalSinceDate:g_fetchedAppSettingsTimestamp] > APPSETTINGS_STALE_THRESHOLD_SECONDS);
}

+ (void)callTheFetchAppSettingsCallback:(void (^)(FBFetchedAppSettings *, NSError *))callback {
    if (callback) {
        if (g_fetchedAppSettingsError) {
            callback(nil, g_fetchedAppSettingsError);
        } else if (g_fetchedAppSettings) {
            callback(g_fetchedAppSettings, nil);
        }
    }
}

+ (NSString *)attributionID {
    return [[UIPasteboard pasteboardWithName:@"fb_app_attribution" create:NO] string];
}

+ (NSString *)advertiserID {
    NSString *advertiserID = nil;
    Class ASIdentifierManagerClass = [FBDynamicFrameworkLoader loadClass:@"ASIdentifierManager" withFramework:@"AdSupport"];
    if ([ASIdentifierManagerClass class]) {
        ASIdentifierManager *manager = [ASIdentifierManagerClass sharedManager];
        advertiserID = [[manager advertisingIdentifier] UUIDString];
    }
    return advertiserID;
}

+ (FBAdvertisingTrackingStatus)advertisingTrackingStatus {
    if ([FBSettings restrictedTreatment] == FBRestrictedTreatmentYES) {
        return AdvertisingTrackingDisallowed;
    }
    FBAdvertisingTrackingStatus status = AdvertisingTrackingUnspecified;
    Class ASIdentifierManagerClass = [FBDynamicFrameworkLoader loadClass:@"ASIdentifierManager" withFramework:@"AdSupport"];
    if ([ASIdentifierManagerClass class]) {
        ASIdentifierManager *manager = [ASIdentifierManagerClass sharedManager];
        if (manager) {
            status = [manager isAdvertisingTrackingEnabled] ? AdvertisingTrackingAllowed : AdvertisingTrackingDisallowed;
        }
    }
    return status;
}

+ (void)updateParametersWithEventUsageLimitsAndBundleInfo:(NSMutableDictionary *)parameters {
    // Only add the iOS global value if we have a definitive allowed/disallowed on advertising tracking.  Otherwise,
    // absence of this parameter is to be interpreted as 'unspecified'.
    FBAdvertisingTrackingStatus advertisingTrackingStatus = [FBUtility advertisingTrackingStatus];
    if (advertisingTrackingStatus != AdvertisingTrackingUnspecified) {
        BOOL allowed = (advertisingTrackingStatus == AdvertisingTrackingAllowed);
        [parameters setObject:[[NSNumber numberWithBool:allowed] stringValue]
                       forKey:@"advertiser_tracking_enabled"];
    }

    [parameters setObject:[[NSNumber numberWithBool:!FBSettings.limitEventAndDataUsage] stringValue] forKey:@"application_tracking_enabled"];

    static dispatch_once_t fetchBundleOnce;
    static NSString *bundleIdentifier;
    static NSMutableArray *urlSchemes;
    static NSString *longVersion;
    static NSString *shortVersion;

    dispatch_once(&fetchBundleOnce, ^{
        NSBundle *mainBundle = [NSBundle mainBundle];
        urlSchemes = [[NSMutableArray alloc] init];
        for (NSDictionary *fields in [mainBundle objectForInfoDictionaryKey:@"CFBundleURLTypes"]) {
            NSArray *schemesForType = [fields objectForKey:@"CFBundleURLSchemes"];
            if (schemesForType) {
                [urlSchemes addObjectsFromArray:schemesForType];
            }
        }
        bundleIdentifier = mainBundle.bundleIdentifier;
        longVersion = [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        shortVersion = [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    });

    if (bundleIdentifier.length > 0) {
        [parameters setObject:bundleIdentifier forKey:@"bundle_id"];
    }
    if (urlSchemes.count > 0) {
        [parameters setObject:[FBUtility simpleJSONEncode:urlSchemes] forKey:@"url_schemes"];
    }
    if (longVersion.length > 0) {
        [parameters setObject:longVersion forKey:@"bundle_version"];
    }
    if (shortVersion.length > 0) {
        [parameters setObject:shortVersion forKey:@"bundle_short_version"];
    }

}

+ (NSString *)simpleJSONEncode:(id)data {
    return [FBUtility simpleJSONEncode:data
                                 error:nil
                        writingOptions:0];
}

+ (NSString *)simpleJSONEncode:(id)data
                         error:(NSError **)error
                writingOptions:(NSJSONWritingOptions)writingOptions {
    if (data) {
        NSData *json = [NSJSONSerialization dataWithJSONObject:data
                                                       options:writingOptions
                                                         error:error];
        return [[[NSString alloc] initWithData:json
                                      encoding:NSUTF8StringEncoding]
                autorelease];
    } else {
        return nil;
    }
}

+ (id)simpleJSONDecode:(NSString *)jsonEncoding {
    return [FBUtility simpleJSONDecode:jsonEncoding error:nil];
}

+ (id)simpleJSONDecode:(NSString *)jsonEncoding
                 error:(NSError **)error {
    NSData *data = [jsonEncoding dataUsingEncoding:NSUTF8StringEncoding];

    if (data) {
        return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    } else {
        return nil;
    }
}

+ (BOOL)isRetinaDisplay {
    // Check for displayLinkWithTarget:selector: since that is only available on iOS 4.0+
    // deal with edge case where scale returns 2.0 on a iPad running 3.2 with 2x
    // (which is not retina).
    static dispatch_once_t onceToken;
    static BOOL supportsRetina;

    dispatch_once(&onceToken, ^{
        supportsRetina = ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
                          ([UIScreen mainScreen].scale == 2.0));
    });
    return supportsRetina;
}

+ (NSString *)newUUIDString {
    // Create the unique action Id
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);

    // We will only hold on to the string representation and not the raw bytes
    NSString *uuidString = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);

    // release the UUID
    CFRelease(uuid);

    return uuidString;
}

+ (BOOL)isRegisteredURLScheme:(NSString *)urlScheme {
    static dispatch_once_t fetchBundleOnce;
    static NSArray *urlTypes = nil;

    dispatch_once(&fetchBundleOnce, ^{
        urlTypes = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleURLTypes"];
    });
    for (NSDictionary *urlType in urlTypes) {
        NSArray *urlSchemes = [urlType valueForKey:@"CFBundleURLSchemes"];
        if ([urlSchemes containsObject:urlScheme]) {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)buildFacebookUrlWithPre:(NSString *)pre {
    return [FBUtility buildFacebookUrlWithPre:pre withPost:nil];
}

+ (NSString *)buildFacebookUrlWithPre:(NSString *)pre
                             withPost:(NSString *)post {
    NSString *domainPart = [FBSettings facebookDomainPart];
    NSString *domain = FB_BASE_URL;
    if (domainPart) {
        domain = [NSString stringWithFormat:@"%@.%@", domainPart, FB_BASE_URL];
    }
    return [NSString stringWithFormat:@"%@%@%@", pre, domain, post ?: @""];
}

+ (BOOL)isMultitaskingSupported {
    return [[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] &&
    [[UIDevice currentDevice] isMultitaskingSupported];
}

+ (BOOL)isSystemAccountStoreAvailable {
    id accountStore = nil;
    id accountTypeFB = nil;

    return (accountStore = [[[NSClassFromString(@"ACAccountStore") alloc] init] autorelease]) &&
    (accountTypeFB = [accountStore accountTypeWithAccountTypeIdentifier:@"com.apple.facebook"]);
}

+ (void)deleteFacebookCookies {
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *facebookCookies = [cookies cookiesForURL:
                                [NSURL URLWithString:[FBUtility dialogBaseURL]]];

    for (NSHTTPCookie *cookie in facebookCookies) {
        [cookies deleteCookie:cookie];
    }
}

+ (NSString *)dialogBaseURL {
    return [FBUtility buildFacebookUrlWithPre:@"https://m." withPost:@"/dialog/"];
}

@end
