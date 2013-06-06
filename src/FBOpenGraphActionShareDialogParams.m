/*
 * Copyright 2013 Facebook
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

#import "FBOpenGraphActionShareDialogParams.h"
#import "FBDialogsParams+Internal.h"
#import "FBUtility.h"
#import "FBAppBridge.h"
#import "FBLogger.h"
#import "FBError.h"

#ifndef FB_BUILD_ONLY
#define FB_BUILD_ONLY
#endif

#import "FBSettings.h"

#ifdef FB_BUILD_ONLY
#undef FB_BUILD_ONLY
#endif

NSString *const FBPostObjectOfType = @"fbsdk:create_object_of_type";
NSString *const FBPostObject = @"fbsdk:create_object";

NSString *const kFBAppBridgeMinVersion = @"20130214";
NSString *const kFBAppBridgeImageSupportVersion = @"20130410";

@implementation FBOpenGraphActionShareDialogParams

- (void)dealloc
{
    [_previewPropertyName release];
    [_actionType release];
    [super dealloc];
}

+ (NSString *)getPostedObjectTypeFromObject:(id<FBGraphObject>)obj {
    if ([(id)obj objectForKey:FBPostObject] &&
        [(id)obj objectForKey:@"type"]) {
        return [(id)obj objectForKey:@"type"];
    }
    return nil;
}
+ (NSString *)getIdOrUrlFromObject:(id<FBGraphObject>)obj {
    id result;
    if ((result = [(id)obj objectForKey:@"id"]) ||
        (result = [(id)obj objectForKey:@"url"])) {
      return result;
    }
    return nil;
}

- (NSError *)validate {
    NSString *errorReason = nil;

    if (!self.action || !self.actionType || !self.previewPropertyName) {
        errorReason = FBErrorDialogInvalidOpenGraphActionParameters;
    } else {
        for (NSString *key in (id)self.action) {
            id obj = [(id)self.action objectForKey:key];
            if ([obj conformsToProtocol:@protocol(FBGraphObject)]) {
                if (![FBOpenGraphActionShareDialogParams getPostedObjectTypeFromObject:obj] &&
                    ![FBOpenGraphActionShareDialogParams getIdOrUrlFromObject:obj]) {
                    errorReason = FBErrorDialogInvalidOpenGraphObject;
                }
            }
        }
    }
    if (errorReason) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        userInfo[FBErrorDialogReasonKey] = errorReason;
        return [NSError errorWithDomain:FacebookSDKDomain
                                   code:FBErrorDialog
                               userInfo:userInfo];
    }
    return nil;
}

- (id)flattenObject:(id)obj {
    if ([obj conformsToProtocol:@protocol(FBGraphObject)]) {
        // #2267154: Temporarily work around change in native protocol. This will be removed
        // before leaving beta. After that, just don't flatten objects that have FBPostObject.
        NSString *postedObjectType;
        NSString *idOrUrl;
        if ((postedObjectType = [FBOpenGraphActionShareDialogParams getPostedObjectTypeFromObject:obj])) {
            if (![FBAppBridge installedFBNativeAppVersionForMethod:@"ogshare"
                                                        minVersion:@"20130410"]) {
                // We only need to do this for pre-20130410 versions.
                [obj setObject:postedObjectType forKey:FBPostObjectOfType];
                [obj removeObjectForKey:FBPostObject];
                [obj removeObjectForKey:@"type"];
            }
        } else if ((idOrUrl = [FBOpenGraphActionShareDialogParams getIdOrUrlFromObject:obj])) {
              return idOrUrl;
        }
    } else if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *flattenedArray = [[[NSMutableArray alloc] init] autorelease];
        for (id val in obj) {
            [flattenedArray addObject:[self flattenObject:val]];
        }
        return flattenedArray;
    }
    return obj;
}

- (id)flattenGraphObjects:(id)dict {
    NSMutableDictionary *flattened = [[[NSMutableDictionary alloc] initWithDictionary:dict] autorelease];
    for (NSString *key in dict) {
        id value = [dict objectForKey:key];
        // Since flattenGraphObjects is only called for the OG action AND image is a special
        // object with attributes that should NOT be flattened (e.g., "user_generated"),
        // we should skip flattening the image dictionary.
        if ([key isEqualToString:@"image"]) {
          [flattened setObject:value forKey:key];
        } else {
          [flattened setObject:[self flattenObject:value] forKey:key];
        }
    }
    return flattened;
}

- (NSDictionary *)dictionaryMethodArgs
{
    NSMutableDictionary *args = [NSMutableDictionary dictionary];
    if (self.action) {
        [args setObject:[self flattenGraphObjects:self.action] forKey:@"action"];
    }
    if (self.actionType) {
        [args setObject:self.actionType forKey:@"actionType"];
    }
    if (self.previewPropertyName) {
        [args setObject:self.previewPropertyName forKey:@"previewPropertyName"];
    }

    return args;
}

- (NSString *)appBridgeVersion
{
    NSString *imgSupportVersion = [FBAppBridge installedFBNativeAppVersionForMethod:@"ogshare"
                                                                         minVersion:kFBAppBridgeImageSupportVersion];
    if (!imgSupportVersion) {
        NSString *minVersion = [FBAppBridge installedFBNativeAppVersionForMethod:@"ogshare" minVersion:kFBAppBridgeMinVersion];
        if ([FBSettings isBetaFeatureEnabled:FBBetaFeaturesOpenGraphShareDialog] && minVersion) {
            if ([self containsUIImages:self.action]) {
                [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                                    logEntry:@"FBOpenGraphActionShareDialogParams: the current Facebook app does not support embedding UIImages."];
                return nil;
            }
            return minVersion;
        }
        return nil;
    }
    return imgSupportVersion;
}

- (BOOL)containsUIImages:(id)param
{
    BOOL containsUIImages = NO;
    NSArray *values = nil;
    if ([param isKindOfClass:[NSDictionary class]]) {
        values = ((NSDictionary *)param).allValues;
    } else if ([param isKindOfClass:[NSArray class]]) {
        values = param;
    } else if ([param isKindOfClass:[UIImage class]]) {
        return YES;
    }
    if (values) {
        for (id value in values) {
            containsUIImages = containsUIImages || [self containsUIImages:value];
        }
    }
    return containsUIImages;
}

@end
