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

#import "FBOpenGraphActionShareDialogParams.h"
#import "FBOpenGraphActionParams+Internal.h"

#import "FBAppBridge.h"
#import "FBAppBridgeScheme.h"
#import "FBDialogsParams+Internal.h"
#import "FBError.h"
#import "FBLogger.h"
#import "FBUtility.h"

#ifndef FB_BUILD_ONLY
#define FB_BUILD_ONLY
#endif

#import "FBSettings.h"

#ifdef FB_BUILD_ONLY
#undef FB_BUILD_ONLY
#endif

NSString *const FBPostObjectOfType = @"fbsdk:create_object_of_type";
NSString *const FBPostObject = @"fbsdk:create_object";

@implementation FBOpenGraphActionShareDialogParams

@end

@interface FBOpenGraphActionParams()
@property (nonatomic, retain) FBAppBridgeScheme *bridgeScheme;
@end

@implementation FBOpenGraphActionParams

- (instancetype)initWithAction:(id<FBOpenGraphAction>) action actionType:(NSString *)actionType previewPropertyName:(NSString *)previewPropertyName {
  if ((self = [super init])) {
    self.action = action;
    self.actionType = actionType;
    self.previewPropertyName = previewPropertyName;
  }
  return self;
}

- (void)dealloc
{
    [_previewPropertyName release];
    [_actionType release];
    [_action release];

    [super dealloc];
}

+ (NSString *)methodName {
    return @"ogshare";
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
    NSString *errorFailureReason = nil;

    if (!self.action || !self.actionType || !self.previewPropertyName) {
        errorReason = FBErrorDialogInvalidOpenGraphActionParameters;
        errorFailureReason = @"You must supply the action, actionType, and previewPropertyName";
    } else {
        BOOL foundPreviewProperty = NO;
        for (NSString *key in (id)self.action) {
            id obj = [(id)self.action objectForKey:key];
            if ([obj conformsToProtocol:@protocol(FBGraphObject)]) {
                if (![FBOpenGraphActionParams getPostedObjectTypeFromObject:obj] &&
                    ![FBOpenGraphActionParams getIdOrUrlFromObject:obj]) {
                    errorReason = FBErrorDialogInvalidOpenGraphObject;
                    errorFailureReason = @"The Open Graph object must either have a url or id, or be marked for creation (e.g., constructed by [FBGraphObject openGraphObjectForPost])";
                }
            }
            if ([key isEqualToString:self.previewPropertyName]) {
                foundPreviewProperty = YES;
            }
        }
        if (!foundPreviewProperty){
            errorReason = FBErrorDialogInvalidOpenGraphActionParameters;
            errorFailureReason = [NSString stringWithFormat:@"There was no object found for previewPropertyName [%@] on the action", self.previewPropertyName];
        }
    }
    if (errorReason) {
        NSDictionary *userInfo = @{ FBErrorDialogReasonKey : errorReason,
                                    NSLocalizedFailureReasonErrorKey : errorFailureReason };
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
        if ((postedObjectType = [FBOpenGraphActionParams getPostedObjectTypeFromObject:obj])) {
            if ([self.bridgeScheme.version compare:@"20130410"] == NSOrderedAscending) {
                // We only need to do this for pre-20130410 versions of the FBApp.
                [obj setObject:postedObjectType forKey:FBPostObjectOfType];
                [obj removeObjectForKey:FBPostObject];
                [obj removeObjectForKey:@"type"];
            }
        } else if ((idOrUrl = [FBOpenGraphActionParams getIdOrUrlFromObject:obj])) {
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
