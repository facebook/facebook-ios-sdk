/*
 * Copyright 2012 Facebook
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

#import "FBUtility.h"
#import "FBGraphObject.h"
#import "FBRequest.h"
#import "FBSBJSON.h"
#import "FBSession.h"

#import <AdSupport/AdSupport.h>
#include <sys/time.h>

static FBFetchedAppSettings *g_fetchedAppSettings = nil;
static NSError *g_fetchedAppSettingsError = nil;

@implementation FBUtility

// finishes the parsing job that NSURL starts
+ (NSDictionary*)dictionaryByParsingURLQueryPart:(NSString *)encodedString {
    
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

// the reverse of url encoding
+ (NSString*)stringByURLDecodingString:(NSString*)escapedString {
    return [[escapedString stringByReplacingOccurrencesOfString:@"+" withString:@" "]
            stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString*)stringByURLEncodingString:(NSString*)unescapedString {
    NSString* result = (NSString *)CFURLCreateStringByAddingPercentEscapes(
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

+ (id<FBGraphObject>)graphObjectInArray:(NSArray*)array withSameIDAs:(id<FBGraphObject>)item {
    for (id<FBGraphObject> obj in array) {
        if ([FBGraphObject isGraphObjectID:obj sameAs:item]) {
            return obj;
        }
    }
    return nil;
}

// The assumption here is that the view and the tableView share a common parent.
+ (void)centerView:(UIView*)view tableView:(UITableView*)tableView {
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

+ (NSDate*)expirationDateFromExpirationTimeString:(NSString*)expirationTime {
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
        NSString *path = [[NSBundle mainBundle] pathForResource:@"FacebookSDKResources"
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

#pragma mark - permissions related

+ (BOOL)isPublishPermission:(NSString*)permission {
    return [permission hasPrefix:@"publish"] ||
    [permission hasPrefix:@"manage"] ||
    [permission isEqualToString:@"ads_management"] ||
    [permission isEqualToString:@"create_event"] ||
    [permission isEqualToString:@"rsvp_event"];
}

+ (BOOL)areAllPermissionsReadPermissions:(NSArray*)permissions {
    for (NSString *permission in permissions) {
        if ([self isPublishPermission:permission]) {
            return NO;
        }
    }
    return YES;
}

+ (NSArray*)addBasicInfoPermission:(NSArray*)permissions {
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
    
    if (!g_fetchedAppSettingsError && !g_fetchedAppSettings) {
    
        NSString *pingPath = [NSString stringWithFormat:@"%@?fields=supports_attribution,supports_implicit_sdk_logging", appID, nil];
        FBRequest *pingRequest = [[[FBRequest alloc] initWithSession:nil graphPath:pingPath] autorelease];
        if ([pingRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            
            if (error) {
                g_fetchedAppSettingsError = error;
                [g_fetchedAppSettingsError retain];
            } else {
                
                g_fetchedAppSettings = [[[FBFetchedAppSettings alloc] init] retain];
                if ([result respondsToSelector:@selector(objectForKey:)]) {
                    g_fetchedAppSettings.supportsAttribution = [[result objectForKey:@"supports_attribution"] boolValue];
                    g_fetchedAppSettings.supportsImplicitSdkLogging = [[result objectForKey:@"supports_implicit_sdk_logging"] boolValue];
                }
            }
            [FBUtility callTheFetchAppSettingsCallback:callback];
          }
         ]
        );
    } else {
        [FBUtility callTheFetchAppSettingsCallback:callback];
    }
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
    if ([ASIdentifierManager class]) {
        ASIdentifierManager *manager = [ASIdentifierManager sharedManager];
        advertiserID = [[manager advertisingIdentifier] UUIDString];
    }
    return advertiserID;
}

+ (FBAdvertisingTrackingStatus)advertisingTrackingStatus {
    FBAdvertisingTrackingStatus status = AdvertisingTrackingUnspecified;
    if ([ASIdentifierManager class]) {
        ASIdentifierManager *manager = [ASIdentifierManager sharedManager];
        if (manager) {
            status = [manager isAdvertisingTrackingEnabled] ? AdvertisingTrackingAllowed : AdvertisingTrackingDisallowed;
        }
    }
    return status;
}

+ (NSString *)simpleJSONEncode:(id)data {
    NSError *error = nil;
    FBSBJSON *writer = [[FBSBJSON alloc] init];
    NSString *result = [writer stringWithFragment:data error:&error];
    FBConditionalLog(!error, @"Shouldn't get a JSON encoding error");
    [writer release];
    return result;
}

+ (id)simpleJSONDecode:(NSString *)jsonEncoding {
    
    if (!jsonEncoding) {
        return nil;
    }
    
    NSError *error = nil;
    FBSBJSON *reader = [[FBSBJSON alloc] init];
    id result = [reader fragmentWithString:jsonEncoding error:&error];
    FBConditionalLog(!error, @"Shouldn't get a JSON decoding error");
    [reader release];
    return result;
}

+ (BOOL) isRetinaDisplay {
    // Check for displayLinkWithTarget:selector: since that is only available on iOS 4.0+
    // deal with edge case where scale returns 2.0 on a iPad running 3.2 with 2x
    // (which is not retina).
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            ([UIScreen mainScreen].scale == 2.0));
}
@end
