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

#import "FacebookSDK.h"
#import "FBAppEvents.h"
#import "FBAppEvents+Internal.h"
#import "FBDialogConfig.h"
#import "FBUtility+Private.h"
#import "FBGraphObject.h"
#import "FBLogger.h"
#import "FBRequest+Internal.h"
#import "FBRequestConnection+Internal.h"
#import "FBSession.h"
#import "FBDynamicFrameworkLoader.h"
#import "FBSettings+Internal.h"

#import <AdSupport/AdSupport.h>
#include <mach-o/dyld.h>
#include <sys/time.h>

static const double APPSETTINGS_STALE_THRESHOLD_SECONDS = 60 * 60; // one hour.
static FBFetchedAppSettings *g_fetchedAppSettings = nil;
static NSError *g_fetchedAppSettingsError = nil;
static NSDate *g_fetchedAppSettingsTimestamp = nil;
static dispatch_group_t g_fetchedAppSettingsDispatchGroup;
static const NSString *kAppSettingsFieldAppName = @"name";
static const NSString *kAppSettingsFieldSupportsImplicitLogging = @"supports_implicit_sdk_logging";
static const NSString *kAppSettingsFieldEnableLoginTooltip = @"gdpv4_nux_enabled";
static const NSString *kAppSettingsFieldLoginTooltipContent = @"gdpv4_nux_content";
static const NSString *kAppSettingsFieldDialogConfigs = @"ios_dialog_configs";
static const NSString *kAppSettingsFieldDialogFlows = @"ios_sdk_dialog_flows";
static const NSString *kAppSettingsFieldAppEventsFeatureBitmask = @"app_events_feature_bitmask";
static const NSString *kAppSettingsFieldSupportsSystemAuth = @"ios_supports_system_auth";

FBTriStateBOOL FBTriStateBOOLFromBOOL(BOOL value) {
    return value ? FBTriStateBOOLValueYES : FBTriStateBOOLValueNO;
}

BOOL BOOLFromFBTriStateBOOL(FBTriStateBOOL value, BOOL defaultValue) {
    switch (value) {
        case FBTriStateBOOLValueYES:
            return YES;
        case FBTriStateBOOLValueNO:
            return NO;
        case FBTriStateBOOLValueUnknown:
            return defaultValue;
    }
}

BOOL FBCheckObjectIsEqual(NSObject *a, NSObject *b)
{
    return (a == b ? YES : [a isEqual:b]);
}

@implementation FBUtility

NSString *const FBPersistedAnonymousIDFilename   = @"com-facebook-sdk-PersistedAnonymousID.json";
NSString *const FBPersistedAnonymousIDKey   = @"anon_id";

#pragma mark Object Helpers

+ (id<FBGraphObject>)graphObjectInArray:(NSArray *)array withSameIDAs:(id<FBGraphObject>)item {
    for (id<FBGraphObject> obj in array) {
        if ([FBGraphObject isGraphObjectID:obj sameAs:item]) {
            return obj;
        }
    }
    return nil;
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

#pragma mark - UI Helpers

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

+ (UIViewController *)topMostViewController
{
  UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
  while (topController.presentedViewController) {
    topController = topController.presentedViewController;
  }
  return topController;
}

#pragma mark - Time / Date

+ (unsigned long)currentTimeInMilliseconds {
    struct timeval time;
    gettimeofday(&time, NULL);
    return (time.tv_sec * 1000) + (time.tv_usec / 1000);
}

+ (NSTimeInterval)randomTimeInterval:(NSTimeInterval)minValue withMaxValue:(NSTimeInterval)maxValue {
    return minValue + (maxValue - minValue) * (double)arc4random() / UINT32_MAX;
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

#pragma mark - Localized strings

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

#pragma mark - Bundle

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

+ (BOOL)isFacebookBundleIdentifier:(NSString *)bundleIdentifier {
    return [bundleIdentifier hasPrefix:@"com.facebook."] ||
    [bundleIdentifier hasPrefix:@".com.facebook."];
}

+ (BOOL)isSafariBundleIdentifier:(NSString *)bundleIdentifier
{
    return ([bundleIdentifier isEqualToString:@"com.apple.mobilesafari"] ||
            [bundleIdentifier isEqualToString:@"com.apple.SafariViewService"]);
}

#pragma mark - Permissions

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

+ (void)addBasicInfoPermission:(NSMutableArray *)permissions {
    // When specifying read permissions, be sure basic info is included; "email" is used
    // as a proxy for basic info permission.
    for (NSString *p in permissions) {
        if ([p isEqualToString:@"email"]) {
            // Already requested, don't need to add it again.
            return;
        }
    }

    [permissions addObject:@"email"];
}

#pragma mark - App Settings

// Make a call to the Graph API to get a variety of data for the app, and on completion, invoke the callback with
// the result.  Cache the result for subsequent invocations.  Expect only to ever be called with one appID.  Results
// with calling with a second appid are undefined (in reality will just return the previously requested app's results).
+ (void)fetchAppSettings:(NSString *)appID
                callback:(void (^)(FBFetchedAppSettings *, NSError *))callback {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_fetchedAppSettingsDispatchGroup = dispatch_group_create();
    });
    // track if we're in the middle of fetching to prevent redundant requests; otherwise, we've blocked the dispatch_group
    // until the last fetch finishes.
    static BOOL isFetching = NO;

    if (!isFetching &&
        ([self isFetchedFBAppSettingsStale] || (!g_fetchedAppSettingsError && !g_fetchedAppSettings))) {
        dispatch_group_enter(g_fetchedAppSettingsDispatchGroup);
        isFetching = YES;
        NSOperatingSystemVersion operatingSystemVersion = FBUtilityGetSystemVersion();
        NSString *dialogFlowsField = [NSString stringWithFormat:@"%@.os_version(%ti.%ti.%ti)",
                                      kAppSettingsFieldDialogFlows,
                                      operatingSystemVersion.majorVersion,
                                      operatingSystemVersion.minorVersion,
                                      operatingSystemVersion.patchVersion];
        NSString *pingPath = [NSString stringWithFormat:@"%@?fields=%@",
                              appID,
                              [@[kAppSettingsFieldAppName,
                                 kAppSettingsFieldSupportsImplicitLogging,
                                 kAppSettingsFieldEnableLoginTooltip,
                                 kAppSettingsFieldLoginTooltipContent,
                                 kAppSettingsFieldDialogConfigs,
                                 dialogFlowsField,
                                 kAppSettingsFieldSupportsSystemAuth,
                                 kAppSettingsFieldAppEventsFeatureBitmask] componentsJoinedByString:@","]
                              ];
        FBRequest *pingRequest = [[[FBRequest alloc] initWithSession:nil graphPath:pingPath] autorelease];
        pingRequest.skipClientToken = YES;
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

                    g_fetchedAppSettings = [[FBFetchedAppSettings alloc] initWithAppID:appID
                                                               appEventsFeatureOptions:[result[kAppSettingsFieldAppEventsFeatureBitmask] unsignedIntegerValue]];
                    g_fetchedAppSettingsTimestamp = [[NSDate date] retain];

                    g_fetchedAppSettings.serverAppName = result[kAppSettingsFieldAppName];
                    g_fetchedAppSettings.supportsImplicitSdkLogging = [result[kAppSettingsFieldSupportsImplicitLogging] boolValue];
                    g_fetchedAppSettings.enableLoginTooltip = [result[kAppSettingsFieldEnableLoginTooltip] boolValue];
                    g_fetchedAppSettings.loginTooltipContent = result[kAppSettingsFieldLoginTooltipContent];
                    g_fetchedAppSettings.dialogConfigs = [self _parseDialogConfigs:result[kAppSettingsFieldDialogConfigs]];
                    g_fetchedAppSettings.dialogFlows = result[kAppSettingsFieldDialogFlows];
                    g_fetchedAppSettings.supportsSystemAuth = [result[kAppSettingsFieldSupportsSystemAuth] boolValue];
                }
            }
            // make sure we clear isFetching before leaving group; otherwise,
            // a callback may be notified and then would not be able to issue
            // another fetch until the flag is set to NO.
            isFetching = NO;
            dispatch_group_leave(g_fetchedAppSettingsDispatchGroup);
        }];
    }
    [self callTheFetchAppSettingsCallback:callback];
}

+ (NSDictionary *)_parseDialogConfigs:(NSDictionary *)dialogConfigsDictionary
{
    NSMutableDictionary *dialogConfigs = [[[NSMutableDictionary alloc] init] autorelease];
    NSArray *dialogConfigsArray = dialogConfigsDictionary[@"data"];
    if ([dialogConfigsArray isKindOfClass:[NSArray class]]) {
        for (NSDictionary *dialogConfigDictionary in dialogConfigsArray) {
            if ([dialogConfigDictionary isKindOfClass:[NSDictionary class]]) {
                FBDialogConfig *dialogConfig = [FBDialogConfig dialogConfigWithDictionary:dialogConfigDictionary];
                if (dialogConfig) {
                    dialogConfigs[dialogConfig.name] = dialogConfig;
                }
            }
        }
    }
    return dialogConfigs;
}

+ (FBFetchedAppSettings *)fetchedAppSettingsIfCurrent {
    if ([self isFetchedFBAppSettingsStale]) {
        return nil;
    }
    return g_fetchedAppSettings;
}

+ (BOOL)isFetchedFBAppSettingsStale {
    return !g_fetchedAppSettingsTimestamp || ([[NSDate date] timeIntervalSinceDate:g_fetchedAppSettingsTimestamp] > APPSETTINGS_STALE_THRESHOLD_SECONDS);
}

+ (void)callTheFetchAppSettingsCallback:(void (^)(FBFetchedAppSettings *, NSError *))callback {
    if (callback) {
        dispatch_group_notify(g_fetchedAppSettingsDispatchGroup, dispatch_get_main_queue(), ^{
            if (g_fetchedAppSettingsError) {
                callback(nil, [[g_fetchedAppSettingsError retain] autorelease]);
            } else if (g_fetchedAppSettings) {
                callback(g_fetchedAppSettings, nil);
            }
        });
    }
}

#pragma mark - IDs / Attribution

+ (NSString *)newUUIDString {
    // Create the unique action Id
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);

    // We will only hold on to the string representation and not the raw bytes
    NSString *uuidString = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);

    // release the UUID
    CFRelease(uuid);

    return uuidString;
}

+ (NSString *)attributionID {
    return [[UIPasteboard pasteboardWithName:@"fb_app_attribution" create:NO] string];
}

+ (NSString *)advertiserID {
    
    NSString *result = nil;
    
    Class ASIdentifierManagerClass = fbdfl_ASIdentifierManagerClass();
    if ([ASIdentifierManagerClass class]) {
        ASIdentifierManager *manager = [ASIdentifierManagerClass sharedManager];
        result = [[manager advertisingIdentifier] UUIDString];
    }
    
    return result;
}

+ (NSString *)anonymousID {
    
    // Grab previously written anonymous ID and, if none have been generated, create and
    // persist a new one which will remain associated with this app.
    NSString *result = [self retrievePersistedAnonymousID];
    if (!result) {
        
        // Generate a new anonymous ID.  Create as a UUID, but then prepend the fairly
        // arbitrary 'XZ' to the front so it's easily distinguishable from IDFA's which
        // will only contain hex.
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        NSString *uuidString = (NSString *) CFUUIDCreateString(NULL, uuid);
        
        result = [NSString stringWithFormat:@"XZ%@", uuidString];
        
        [self persistAnonymousID:result];
        CFRelease(uuid);
        [uuidString release];
    }
    
    return result;
}


+ (void)persistAnonymousID:(NSString *)anonymousID {
    
    [FBAppEvents ensureOnMainThread];
    NSDictionary *data = @{ FBPersistedAnonymousIDKey : anonymousID };
    NSString *content = [FBUtility simpleJSONEncode:data];
    
    [content writeToFile:[FBAppEvents persistenceLibraryFilePath:FBPersistedAnonymousIDFilename]
              atomically:YES
                encoding:NSStringEncodingConversionAllowLossy
                   error:nil];
}

+ (NSString *)retrievePersistedAnonymousID {
    [FBAppEvents ensureOnMainThread];
    NSString *content =
        [[NSString alloc] initWithContentsOfFile:[FBAppEvents persistenceLibraryFilePath:FBPersistedAnonymousIDFilename]
                                    usedEncoding:nil
                                           error:nil];
    NSDictionary *results = [FBUtility simpleJSONDecode:content];
    [content release];
    return [results objectForKey:FBPersistedAnonymousIDKey];
}


+ (FBAdvertisingTrackingStatus)advertisingTrackingStatus {
    if ([FBSettings restrictedTreatment] == FBRestrictedTreatmentYES) {
        return AdvertisingTrackingDisallowed;
    }
    
    static dispatch_once_t fetchAdvertisingTrackingStatusOnce;
    static FBAdvertisingTrackingStatus status;
    
    dispatch_once(&fetchAdvertisingTrackingStatusOnce, ^{
        status = AdvertisingTrackingUnspecified;
        Class ASIdentifierManagerClass = fbdfl_ASIdentifierManagerClass();
        if ([ASIdentifierManagerClass class]) {
            ASIdentifierManager *manager = [ASIdentifierManagerClass sharedManager];
            if (manager) {
                status = [manager isAdvertisingTrackingEnabled] ? AdvertisingTrackingAllowed : AdvertisingTrackingDisallowed;
            }
        }
    });

    return status;
}

+ (NSMutableDictionary<FBGraphObject> *)activityParametersDictionaryForEvent:(NSString *)eventCategory
                                                          implicitEventsOnly:(BOOL)implicitEventsOnly
                                                   shouldAccessAdvertisingID:(BOOL)shouldAccessAdvertisingID {

    NSMutableDictionary<FBGraphObject> *parameters = [FBGraphObject graphObject];
    [parameters setObject:eventCategory forKey:@"event"];

    NSString *attributionID = [FBUtility attributionID];  // Only present on iOS 6 and below.
    if (attributionID) {
        [parameters setObject:attributionID forKey:@"attribution"];
    }

    if (!implicitEventsOnly && shouldAccessAdvertisingID) {
        NSString *advertiserID = [FBUtility advertiserID];
        if (advertiserID) {
            [parameters setObject:advertiserID forKey:@"advertiser_id"];
        }
    }

    [parameters setObject:[self anonymousID] forKey:@"anon_id"];
    
    FBAdvertisingTrackingStatus advertisingTrackingStatus = [self advertisingTrackingStatus];
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
        bundleIdentifier = [mainBundle.bundleIdentifier copy];
        longVersion = [[mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"] copy];
        shortVersion = [[mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] copy];
    });

    if (bundleIdentifier.length > 0) {
        [parameters setObject:bundleIdentifier forKey:@"bundle_id"];
    }
    if (urlSchemes.count > 0) {
        [parameters setObject:[self simpleJSONEncode:urlSchemes] forKey:@"url_schemes"];
    }
    if (longVersion.length > 0) {
        [parameters setObject:longVersion forKey:@"bundle_version"];
    }
    if (shortVersion.length > 0) {
        [parameters setObject:shortVersion forKey:@"bundle_short_version"];
    }
    
    return parameters;
}

#pragma mark - JSON Encode / Decode

+ (NSString *)simpleJSONEncode:(id)data {
    return [self simpleJSONEncode:data
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
    return [self simpleJSONDecode:jsonEncoding error:nil];
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

#pragma mark - URLs Params Encode / Decode

+ (NSDictionary *)queryParamsDictionaryFromFBURL:(NSURL *)url {
    // version 3.2.3 of the Facebook app encodes the parameters in the query but
    // version 3.3 and above encode the parameters in the fragment;
    // merge them together with fragment taking priority.

    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if ([url query]) {
        [result addEntriesFromDictionary:[self dictionaryByParsingURLQueryPart:[url query]]];
    }
    if ([url fragment]) {
        [result addEntriesFromDictionary:[self dictionaryByParsingURLQueryPart:[url fragment]]];
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

        key = [self stringByURLDecodingString:key];
        value = [self stringByURLDecodingString:value];
        if (key && value) {
            result[key] = value;
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
                value = [self stringByURLEncodingString:value];
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

#pragma mark - URLs Builder

+ (NSString *)stringAppBaseUrlFromAppId:(NSString *)appID urlSchemeSuffix:(NSString *)urlSchemeSuffix {
    return [NSString stringWithFormat:@"fb%@%@://authorize",
            appID ?: @"",
            urlSchemeSuffix ?: @""];
}

+ (NSString *)buildFacebookUrlWithPre:(NSString *)pre {
    return [self buildFacebookUrlWithPre:pre post:nil version:nil];
}

+ (NSString *)buildFacebookUrlWithPre:(NSString *)pre
                             withPost:(NSString *)post {
    return [self buildFacebookUrlWithPre:pre post:post version:nil];
}

+ (NSString *)buildFacebookUrlWithPre:(NSString *)pre
                                 post:(NSString *)post
                              version:(NSString *)version {
    // break-out domainPart, domain, version and post
    NSString *domainPart = [FBSettings facebookDomainPart];
    NSString *domain = FB_BASE_URL;

    version = version ?: [FBSettings platformVersion];
    if (version.length) {
        version = [NSString stringWithFormat:@"/%@", version];
    }

    post = post ?: @"";

    if ([post length] > 2 &&
        version.length &&
        // clear the auto version if there is already a version in the form v#.# in path
        [post characterAtIndex:1] == 'v') {
        int grammarPart = 0;
        int index = 2;
        BOOL clearVersion = NO;
        while (post.length > index) {
            unichar c = [post characterAtIndex:index];
            if (grammarPart == 0) { // first - digit
                if ([NSCharacterSet.decimalDigitCharacterSet characterIsMember:c]) {
                    grammarPart++;
                } else {
                    break;
                }
            } else if (grammarPart == 1) {
                if (c == '.') { // second - n digits or dot
                    clearVersion = YES;
                    grammarPart++;
                } else if (![NSCharacterSet.decimalDigitCharacterSet characterIsMember:c]) {
                    break;
                }
            } 
            index++;
        }
        if (clearVersion) {
            version = @"";
        }
    }

    // construct url
    if (domainPart) {
        domain = [NSString stringWithFormat:@"%@.%@", domainPart, FB_BASE_URL];
    }
    NSString *result = [NSString stringWithFormat:@"%@%@%@%@", pre, domain, version, post];
    return result;
}

+ (NSString *)dialogBaseURL {
    return [self buildFacebookUrlWithPre:@"https://m." withPost:@"/dialog/"];
}

#pragma mark - System Info

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

+ (BOOL)isMultitaskingSupported {
    return [[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] &&
    [[UIDevice currentDevice] isMultitaskingSupported];
}

+ (BOOL)isUIKitLinkedOnOrAfter:(FBIOSVersion)version {
    static NSInteger UIKitMajorVersion;

    static dispatch_once_t getVersionOnce;
    dispatch_once(&getVersionOnce, ^{
        enum {
            kMajorVersionMask = 0xFFFF0000,
            kMinorVersionMask = 0x0000FF00,
            kPatchVersionMask = 0x000000FF,

            kMajorVersionShift = 16,
            kMinorVersionShift =  8,
            kPatchVersionShift =  0,
        };

        int32_t linkedWithVersion = NSVersionOfLinkTimeLibrary("UIKit");
        if (linkedWithVersion != -1) {
            UIKitMajorVersion = (linkedWithVersion & kMajorVersionMask) >> kMajorVersionShift;
        } else {
            // Somehow the main executable did not link against UIKit, so the answer is NO.
            UIKitMajorVersion = NSIntegerMin;
        }
    });

    static const NSInteger UIKitLibraryVersionNumbers[] = {
        0x0944, // 6.0
        0x094c, // 6.1
        0x0b57, // 7.0
        0x0b77, // 7.1
        0x0ce6, // 8.0 Beta 5
        0x0db1, // 9.0 Beta 5
    };
    _Static_assert(sizeof(UIKitLibraryVersionNumbers) / sizeof(UIKitLibraryVersionNumbers[0]) == FBIOSVersionCount, "The iOS version enum to UIKit library version number table is out of sync.");

    return (version >= 0 && version < sizeof(UIKitLibraryVersionNumbers) / sizeof(UIKitLibraryVersionNumbers[0])) && // sanity check
        UIKitMajorVersion >= UIKitLibraryVersionNumbers[version];
}

+ (BOOL)isRunningOnOrAfter:(FBIOSVersion)version {
    static NSOperatingSystemVersion systemVersion;

    static dispatch_once_t getVersionOnce;
    dispatch_once(&getVersionOnce, ^{
        systemVersion = FBUtilityGetSystemVersion();
    });

    return FBUtilityIsSystemVersionIOSVersionOrLater(systemVersion, version);
}

+ (BOOL)isSystemAccountStoreAvailable {
    id accountStore = nil;
    id accountTypeFB = nil;

    return (accountStore = [[[NSClassFromString(@"ACAccountStore") alloc] init] autorelease]) &&
    (accountTypeFB = [accountStore accountTypeWithAccountTypeIdentifier:@"com.apple.facebook"]);
}

#pragma mark - Cookies

+ (void)deleteFacebookCookies {
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *facebookCookies = [cookies cookiesForURL:
                                [NSURL URLWithString:[self dialogBaseURL]]];

    for (NSHTTPCookie *cookie in facebookCookies) {
        [cookies deleteCookie:cookie];
    }
}

@end

NSOperatingSystemVersion FBUtilityGetSystemVersion(void) {
    NSOperatingSystemVersion systemVersion = { 0 };

    if ([NSProcessInfo instancesRespondToSelector:@selector(operatingSystemVersion)]) {
        systemVersion = [NSProcessInfo processInfo].operatingSystemVersion;
    } else {
        NSArray *components = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
        switch (components.count) {
            default:
            case 3:
                systemVersion.patchVersion = [components[2] integerValue];
                // fall through
            case 2:
                systemVersion.minorVersion = [components[1] integerValue];
                // fall through
            case 1:
                systemVersion.majorVersion = [components[0] integerValue];
                break;

            case 0:
                systemVersion.majorVersion = NSClassFromString(@"UIDynamicBehavior") ? 7 : 6;
                break;
        }
    }

    return systemVersion;
}

BOOL FBUtilityIsSystemVersionIOSVersionOrLater(NSOperatingSystemVersion systemVersion, FBIOSVersion version) {
    static const NSOperatingSystemVersion IOSVersionNumbers[] = {
        { 6, 0, 0 },
        { 6, 1, 0 },
        { 7, 0, 0 },
        { 7, 1, 0 },
        { 8, 0, 0 },
        { 9, 0, 0 },
    };
    _Static_assert(sizeof(IOSVersionNumbers) / sizeof(IOSVersionNumbers[0]) == FBIOSVersionCount, "The iOS version enum to iOS version number table is out of sync.");

    return (version >= 0 && version < sizeof(IOSVersionNumbers) / sizeof(IOSVersionNumbers[0])) && // sanity check
        (systemVersion.majorVersion > IOSVersionNumbers[version].majorVersion ||
        (systemVersion.majorVersion == IOSVersionNumbers[version].majorVersion && systemVersion.minorVersion > IOSVersionNumbers[version].minorVersion) ||
        (systemVersion.majorVersion == IOSVersionNumbers[version].majorVersion && systemVersion.minorVersion == IOSVersionNumbers[version].minorVersion && systemVersion.patchVersion >= IOSVersionNumbers[version].patchVersion));
}
