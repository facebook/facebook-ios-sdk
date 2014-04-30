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
#import "FBDialogsParams+Internal.h"
#import "FBLinkShareParams.h"
#import "FBLogger.h"
#import "FBOpenGraphActionParams+Internal.h"
#import "FBUtility.h"

#define WRAP_ARRAY(array__) ([NSArray arrayWithObjects:(array__) count:(sizeof((array__)) / sizeof((array__)[0]))])

#ifndef FB_BUILD_ONLY
#define FB_BUILD_ONLY
#endif

#import "FBSettings.h"

#ifdef FB_BUILD_ONLY
#undef FB_BUILD_ONLY
#endif

static NSString *const kFBHttpScheme  = @"http";
static NSString *const kFBHttpsScheme = @"https";
static NSString *const kFBShareDialogBetaVersion = @"20130214";
static NSString *const kFBShareDialogProdVersion = @"20130410";
static NSString *const kFBShareDialogPhotosProdVersion = @"20140116";
static NSString *const kFBAppBridgeMinVersion = @"20130214";
static NSString *const kFBAppBridgeImageSupportVersion = @"20130410";
static NSString *const kFBLikeButtonBetaVersion = @"20140410";

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

// private init.
- (instancetype)initWithVersion:(NSString *)version {
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

+ (NSString *)schemePrefix {
    return @"fbapi";
}

+ (NSArray *)bridgeVersions {
    return WRAP_ARRAY(FBAppBridgeVersions);
}

+ (instancetype)bridgeSchemeForFBAppForShareDialogParams:(FBLinkShareParams *)params {
    if (params.link && ![self isSupportedScheme:params.link.scheme]) {
        return nil;
    }
    if (params.picture && ![self isSupportedScheme:params.picture.scheme]) {
        return nil;
    }

    NSString *minVersion = kFBShareDialogProdVersion;
    NSString *prodVersion = [self installedFBNativeAppVersionForMethod:@"share" minVersion:minVersion];
    if (!prodVersion) {
        if (![FBSettings isBetaFeatureEnabled:FBBetaFeaturesShareDialog]) {
            return nil;
        }
        prodVersion = [self installedFBNativeAppVersionForMethod:@"share" minVersion:kFBShareDialogBetaVersion];
    }
    if (!prodVersion) {
        return nil;
    }
    return [[[self alloc] initWithVersion:prodVersion] autorelease];

}

+ (instancetype)bridgeSchemeForFBAppForShareDialogPhotos
{
    NSString *prodVersion = [self installedFBNativeAppVersionForMethod:@"share" minVersion:kFBShareDialogPhotosProdVersion];
    if (!prodVersion) {
        return nil;
    }
    return [[[self alloc] initWithVersion:prodVersion] autorelease];
}

+ (instancetype)bridgeSchemeForFBAppForOpenGraphActionShareDialogParams:(FBOpenGraphActionParams *)params {
    NSString *imgSupportVersion = [self installedFBNativeAppVersionForMethod:@"ogshare" minVersion:kFBAppBridgeImageSupportVersion];
    if (!imgSupportVersion) {
        NSString *minVersion = [self installedFBNativeAppVersionForMethod:@"ogshare" minVersion:kFBAppBridgeMinVersion];
        if ([FBSettings isBetaFeatureEnabled:FBBetaFeaturesOpenGraphShareDialog] && minVersion) {
            if ([params containsUIImages:params.action]) {
                [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                                    logEntry:@"FBOpenGraphActionShareDialogParams: the current Facebook app does not support embedding UIImages."];
                return nil;
            }
            imgSupportVersion = minVersion;
        }
    }
    if (!imgSupportVersion) {
        return nil;
    }
    return [[[self alloc] initWithVersion:imgSupportVersion] autorelease];
}

+ (instancetype)bridgeSchemeForFBAppForLike
{
    NSString *version = [self installedFBNativeAppVersionForMethod:@"like"
                                                        minVersion:kFBLikeButtonBetaVersion];
    return (version ? [[[self alloc] initWithVersion:version] autorelease] : nil);
}

+ (instancetype)bridgeSchemeForFBMessengerForShareDialogParams:(FBLinkShareParams *)params {
    NSString *version = [_FBMAppBridgeScheme installedFBNativeAppVersionForMethod:@"share"
                                                                       minVersion:FBMessageDialogVersion];
    return (version ? [[[_FBMAppBridgeScheme alloc] initWithVersion:version] autorelease] : nil);
}

+ (instancetype)bridgeSchemeForFBMessengerForShareDialogPhotos; {
    NSString *version = [_FBMAppBridgeScheme installedFBNativeAppVersionForMethod:@"share"
                                                                       minVersion:FBMessageDialogVersion];
    return (version ? [[[_FBMAppBridgeScheme alloc] initWithVersion:version] autorelease] : nil);
}

+ (instancetype)bridgeSchemeForFBMessengerForOpenGraphActionShareDialogParams:(FBOpenGraphActionParams *)params {
    NSString *version = [_FBMAppBridgeScheme installedFBNativeAppVersionForMethod:@"ogshare"
                                                                       minVersion:FBMessageDialogVersion];
    return (version ? [[[_FBMAppBridgeScheme alloc] initWithVersion:version] autorelease] : nil);
}

+ (BOOL)isSupportedScheme:(NSString *)scheme
{
    return ([[scheme lowercaseString] isEqualToString:kFBHttpScheme] ||
            [[scheme lowercaseString] isEqualToString:kFBHttpsScheme]);
}

- (NSURL *)urlForMethod:(NSString *)method
            queryParams:(NSDictionary *)queryParams {
    NSString *schemeVersion = self.version;
    NSString *urlString = [NSString stringWithFormat:@"%@://", [[self class] schemePrefix]];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlString]]) {
        schemeVersion = @"";
    }
    return [[self class] urlForMethod:method
                          queryParams:queryParams
                        schemeVersion:schemeVersion
                              version:self.version];
}

#pragma mark - Private Implementation

+ (NSURL *)urlForMethod:(NSString *)method
            queryParams:(NSDictionary *)queryParams
          schemeVersion:(NSString *)schemeVersion
                version:(NSString *)version {
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

+ (NSString *)installedFBNativeAppVersionForMethod:(NSString *)method
                                        minVersion:(NSString *)minVersion {
    NSArray *bridgeVersions = [[self class] bridgeVersions];
    NSString *version = nil;
    for (NSInteger index = bridgeVersions.count - 1; index >= 0; index--) {
        version = bridgeVersions[index];
        BOOL isMinVersion = [version isEqualToString:minVersion];
        NSURL *url = [self urlForMethod:method
                            queryParams:nil
                          schemeVersion:version
                                version:version];
        if (![[UIApplication sharedApplication] canOpenURL:url]) {
            version = nil;
        }

        if (version || isMinVersion) {
            // Either we found an installed version, or we just hit the minimum
            // version for this method and did not find it to be installed.
            // In either case, we are done searching
            break;
        }
    }

    return version;
}

@end
