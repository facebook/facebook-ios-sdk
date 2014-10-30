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

#import "FBAppBridgeScheme+Subclass.h"

#import "_FBMAppBridgeScheme.h"
#import "FBAppBridge.h"
#import "FBDialogConfig.h"
#import "FBDialogsParams+Internal.h"
#import "FBInternalSettings.h"
#import "FBLinkShareParams.h"
#import "FBLogger.h"
#import "FBOpenGraphActionParams+Internal.h"
#import "FBUtility.h"
#import "FBWebAppBridgeScheme.h"

#define WRAP_ARRAY(array__) ([NSArray arrayWithObjects:(array__) count:(sizeof((array__)) / sizeof((array__)[0]))])

static NSString *const kFBHttpScheme  = @"http";
static NSString *const kFBHttpsScheme = @"https";
static NSString *const kFBShareDialogVersion = @"20130410";
static NSString *const kFBShareDialogPhotosVersion = @"20140116";
static NSString *const kFBAppBridgeMinVersion = @"20130214";
static NSString *const kFBAppBridgeImageSupportVersion = @"20130410";
static NSString *const kFBLikeButtonVersion = @"20140410";

/*
 Array of known versions that the native FB app can support.
 They should be ordered with each element being a more recent version than the previous.

 Format of a version : <yyyy><mm><dd>
 */
static NSString *const FBAppBridgeVersions[] = {
    @"20130214",
    @"20130410",
    @"20130702",
    @"20131010",
    @"20131219",
    @"20140116",
    @"20140410",
};
@implementation FBAppBridgeScheme

static NSDictionary *g_dialogConfigs = nil;
static NSString *const FBDialogConfigsKey = @"com.facebook.sdk:dialogConfigs%@";

+ (void)initialize
{
    if (self == [FBAppBridgeScheme class]) {
        [self updateDialogConfigs];
    }
}

+ (void)updateDialogConfigs
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void(^block)() = ^{
            // while this map is stored globally in FBFetchedAppSettings, we need to serialize it to disk so that it is
            // persistent, so we will be storing it in another global here, and then replacing it once
            // FBFetchedAppSettings has been loaded so that we always have something to read from once it has been
            // loaded at least once.
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *appID = [FBSettings defaultAppID];
            NSString *dialogConfigKey = [NSString stringWithFormat:FBDialogConfigsKey, appID];
            NSData *configData = [defaults objectForKey:dialogConfigKey];
            if ([configData isKindOfClass:[NSData class]]) {
                NSDictionary *dialogConfigs = [NSKeyedUnarchiver unarchiveObjectWithData:configData];
                if ([dialogConfigs isKindOfClass:[NSDictionary class]]) {
                    g_dialogConfigs = [dialogConfigs copy];
                }
            }
            [FBUtility fetchAppSettings:appID callback:^(FBFetchedAppSettings *settings, NSError *error) {
                if (error) {
                    return;
                }
                NSDictionary *dialogConfigs = settings.dialogConfigs;
                [g_dialogConfigs autorelease];
                g_dialogConfigs = [dialogConfigs copy];
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dialogConfigs];
                [defaults setObject:data forKey:dialogConfigKey];
            }];
        };
        if ([NSThread isMainThread]) {
            block();
        } else {
            dispatch_async(dispatch_get_main_queue(), block);
        }
    });
}

// private init.
- (instancetype)initWithVersion:(NSString *)version
{
    if ((self = [super init])) {
        NSAssert(version != nil, @"cannot initialize bridge scheme with nil version");
        _version = [version copy];
    }
    return self;
}

- (void)dealloc
{
    [_version release];
    [super dealloc];
}

+ (NSString *)schemePrefix
{
    return @"fbapi";
}

+ (NSArray *)bridgeVersions
{
    return WRAP_ARRAY(FBAppBridgeVersions);
}

+ (instancetype)bridgeSchemeForFBAppForShareDialogParams:(FBLinkShareParams *)params
{
    if (params.link && ![self isSupportedScheme:params.link.scheme]) {
        return nil;
    }
    if (params.picture && ![self isSupportedScheme:params.picture.scheme]) {
        return nil;
    }

    return [self _validAppBridgeSchemeForMethod:@"share" minVersion:kFBShareDialogVersion];
}

+ (instancetype)bridgeSchemeForFBAppForShareDialogPhotos
{
    return [self _validAppBridgeSchemeForMethod:@"share" minVersion:kFBShareDialogPhotosVersion];
}

+ (instancetype)bridgeSchemeForFBAppForOpenGraphActionShareDialogParams:(FBOpenGraphActionParams *)params
{
    FBAppBridgeScheme *bridgeScheme = [self _validAppBridgeSchemeForMethod:@"ogshare"
                                                                minVersion:kFBAppBridgeImageSupportVersion];
    if (!bridgeScheme) {
        bridgeScheme = [self _validAppBridgeSchemeForMethod:@"ogshare" minVersion:kFBAppBridgeMinVersion];
        if (bridgeScheme && [params containsUIImages:params.action]) {
            [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                                logEntry:
             @"FBOpenGraphActionShareDialogParams: the current Facebook app does not support embedding UIImages."];
            return nil;
        }
    }
    return bridgeScheme;
}

+ (instancetype)bridgeSchemeForFBAppForLike
{
    return [self _validAppBridgeSchemeForMethod:@"like" minVersion:kFBLikeButtonVersion];
}

+ (instancetype)bridgeSchemeForFBMessengerForShareDialogParams:(FBLinkShareParams *)params
{
    return [_FBMAppBridgeScheme _validAppBridgeSchemeForMethod:@"share" minVersion:FBMessageDialogVersion];
}

+ (instancetype)bridgeSchemeForFBMessengerForShareDialogPhotos
{
    return [_FBMAppBridgeScheme _validAppBridgeSchemeForMethod:@"share" minVersion:FBMessageDialogVersion];
}

+ (instancetype)bridgeSchemeForFBMessengerForOpenGraphActionShareDialogParams:(FBOpenGraphActionParams *)params
{
    return [_FBMAppBridgeScheme _validAppBridgeSchemeForMethod:@"ogshare" minVersion:FBMessageDialogVersion];
}

+ (BOOL)isSupportedScheme:(NSString *)scheme
{
    return ([[scheme lowercaseString] isEqualToString:kFBHttpScheme] ||
            [[scheme lowercaseString] isEqualToString:kFBHttpsScheme]);
}

- (NSURL *)URLForMethod:(NSString *)method queryParams:(NSDictionary *)queryParams
{
    NSString *schemeVersion = self.version;
    NSString *urlString = [NSString stringWithFormat:@"%@://", [[self class] schemePrefix]];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlString]]) {
        schemeVersion = @"";
    }
    return [[self class] _URLForMethod:method
                           queryParams:queryParams
                         schemeVersion:schemeVersion
                               version:self.version];
}

#pragma mark - Private Implementation

+ (instancetype)_installedAppBridgeSchemeForMethod:(NSString *)method minVersion:(NSString *)minVersion
{
    UIApplication *application = [UIApplication sharedApplication];
    __block FBAppBridgeScheme *bridgeScheme = nil;
    void(^block)(NSString *, NSUInteger, BOOL *) = ^(NSString *version, NSUInteger idx, BOOL *stop) {
        NSURL *URL = [self _URLForMethod:method queryParams:nil schemeVersion:version version:version];
        if ([application canOpenURL:URL]) {
            bridgeScheme = [[self alloc] initWithVersion:version];
            *stop = YES;
        }
        if ([version isEqualToString:minVersion]) {
            *stop = YES;
        }
    };
    [[[self class] bridgeVersions] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:block];
    return [bridgeScheme autorelease];
}

+ (NSURL *)_URLForMethod:(NSString *)method
             queryParams:(NSDictionary *)queryParams
           schemeVersion:(NSString *)schemeVersion
                 version:(NSString *)version
{
    if (version) {
        NSMutableDictionary *mutableQueryParams = [NSMutableDictionary dictionaryWithDictionary:queryParams];
        mutableQueryParams[@"version"] = version;
        queryParams = mutableQueryParams;
    }
    NSString *queryParamsStr = (queryParams) ? [FBUtility stringBySerializingQueryParameters:queryParams] : @"";
    return [NSURL URLWithString:[NSString stringWithFormat:
                                 @"%@%@://dialog/%@?%@",
                                 [[self class] schemePrefix],
                                 schemeVersion,
                                 method,
                                 queryParamsStr]];
}

+ (instancetype)_validAppBridgeSchemeForMethod:(NSString *)method minVersion:(NSString *)minVersion
{
    FBDialogConfig *config = g_dialogConfigs[method];

    if (config) {
        // if we have a config, then we want to use the rules for that only
        return [self _validAppBridgeSchemeWithConfig:config forMethod:method];
    } else {
        // we don't have a config for this method, so go through the known versions and look for one that is installed
        return [self _installedAppBridgeSchemeForMethod:method minVersion:minVersion];
    }
}

+ (instancetype)_validAppBridgeSchemeWithConfig:(FBDialogConfig *)config forMethod:(NSString *)method
{
    UIApplication *application = [UIApplication sharedApplication];
    __block FBAppBridgeScheme *bridgeScheme = nil;
    void(^block)(NSString *, NSUInteger, BOOL *) = ^(NSString *version, NSUInteger idx, BOOL *stop) {
        NSURL *URL = [self _URLForMethod:method queryParams:nil schemeVersion:version version:version];
        if ([application canOpenURL:URL]) {
            // if the idx is odd, then it is a disabled version, so we want to break with a nil bridgeScheme, else we
            // want to use this version
            if (idx % 2 == 0) {
                bridgeScheme = [[self alloc] initWithVersion:version];
            }
            *stop = YES;
        }
    };
    [config.versions enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:block];
    return ([bridgeScheme autorelease] ?:
            [[[FBWebAppBridgeScheme alloc] initWithURL:config.URL method:method] autorelease]);
}

@end
