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

#import "FBAppBridgeScheme.h"

#import "FBAppBridge.h"
#import "FBDialogsParams+Internal.h"
#import "FBLogger.h"
#import "FBLoginDialogParams.h"
#import "FBOpenGraphActionShareDialogParams+Internal.h"
#import "FBShareDialogParams.h"
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
static NSString *const kFBNativeLoginMinVersion = @"20131219";
static NSString *const kFBShareDialogBetaVersion = @"20130214";
static NSString *const kFBShareDialogProdVersion = @"20130410";
static NSString *const kFBShareDialogPhotosProdVersion = @"20140116";
static NSString *const kFBAppBridgeMinVersion = @"20130214";
static NSString *const kFBAppBridgeImageSupportVersion = @"20130410";
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
    @"20140214",
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

+ (FBAppBridgeScheme *)bridgeSchemeForFBAppForShareDialogParams:(FBShareDialogParams *)params {
    if (params.link && ![FBAppBridgeScheme isSupportedScheme:params.link.scheme]) {
        return nil;
    }
    if (params.picture && ![FBAppBridgeScheme isSupportedScheme:params.picture.scheme]) {
        return nil;
    }

    NSString *minVersion = kFBShareDialogProdVersion;
    NSString *prodVersion = [FBAppBridgeScheme installedFBNativeAppVersionForMethod:@"share"
                                                                         minVersion:minVersion];
    if (!prodVersion) {
        if (![FBSettings isBetaFeatureEnabled:FBBetaFeaturesShareDialog]) {
            return nil;
        }
        prodVersion = [FBAppBridgeScheme installedFBNativeAppVersionForMethod:@"share"
                                                                   minVersion:kFBShareDialogBetaVersion];
    }
    if (!prodVersion) {
        return nil;
    }
    return [[[FBAppBridgeScheme alloc] initWithVersion:prodVersion] autorelease];

}

+ (FBAppBridgeScheme *)bridgeSchemeForFBAppForShareDialogPhotos
{
    NSString *prodVersion = [FBAppBridgeScheme installedFBNativeAppVersionForMethod:@"share"
                                                                         minVersion:kFBShareDialogPhotosProdVersion];
    if (!prodVersion) {
        return nil;
    }
    return [[[FBAppBridgeScheme alloc] initWithVersion:prodVersion] autorelease];
}

+ (FBAppBridgeScheme *)bridgeSchemeForFBAppForOpenGraphActionShareDialogParams:(FBOpenGraphActionShareDialogParams *)params {
    NSString *imgSupportVersion = [FBAppBridgeScheme installedFBNativeAppVersionForMethod:@"ogshare"
                                                                               minVersion:kFBAppBridgeImageSupportVersion];
    if (!imgSupportVersion) {
        NSString *minVersion = [FBAppBridgeScheme installedFBNativeAppVersionForMethod:@"ogshare"
                                                                            minVersion:kFBAppBridgeMinVersion];
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
    return [[[FBAppBridgeScheme alloc] initWithVersion:imgSupportVersion] autorelease];
}

+ (FBAppBridgeScheme *)bridgeSchemeForFBAppForLoginParams:(FBLoginDialogParams *)params {
    // Select the right minimum version for the passed in combination of params.
    NSString *version = [FBAppBridgeScheme installedFBNativeAppVersionForMethod:@"auth3"
                                                                     minVersion:kFBNativeLoginMinVersion];
    if (![FBSettings defaultDisplayName] && [version isEqualToString:kFBNativeLoginMinVersion]) {
        // We have the first version of Native Login that does not look up the app's display
        // name from the Facebook App with a server request. So we can't proceed.
        version = nil;
    }
    if (!version) {
        return nil;
    }
    return [[[FBAppBridgeScheme alloc] initWithVersion:version] autorelease];
}

+ (BOOL)isSupportedScheme:(NSString *)scheme
{
    return ([[scheme lowercaseString] isEqualToString:kFBHttpScheme] ||
            [[scheme lowercaseString] isEqualToString:kFBHttpsScheme]);
}

- (NSURL *)urlForMethod:(NSString *)method
            queryParams:(NSDictionary *)queryParams {
    NSString *schemeVersion = self.version;
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fbapi://"]]) {
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
                                 @"fbapi%@://dialog/%@?%@",
                                 schemeVersion,
                                 method,
                                 queryParamsStr]];
}

+ (NSString *)installedFBNativeAppVersionForMethod:(NSString *)method
                                        minVersion:(NSString *)minVersion {
    NSArray *bridgeVersions = WRAP_ARRAY(FBAppBridgeVersions);
    NSString *version = nil;
    for (NSInteger index = bridgeVersions.count - 1; index >= 0; index--) {
        version = bridgeVersions[index];
        BOOL isMinVersion = [version isEqualToString:minVersion];
        NSURL *url = [FBAppBridgeScheme urlForMethod:method
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
