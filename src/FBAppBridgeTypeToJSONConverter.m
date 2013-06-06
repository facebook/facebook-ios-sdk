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

#import <UIKit/UIKit.h>
#import "FBBase64.h"
#import "FBError.h"
#import "FBAppBridgeTypeToJSONConverter.h"
#import "FBSettings+Internal.h"

/*
 jsonReadyValue: A representation of the extended type that is safe for JSON serialization.
 isPasteboard: Used to determine if the original value was stored in a UIPasteboard. If set,
 then jsonReadyValue is the name of the pasteboard.
 isBase64: Used to determine if the original value was Base64 encoded. If set, then the encoded
 value has been set directly in jsonReadyValue.
 tag: Used to determine what kind of object was originally converted to be JSON ready.
 */
static const struct {
    NSString *jsonReadyValue;
    NSString *isPasteboard;
    NSString *isBase64;
    NSString *tag;
} FBAppBridgeTypesMetadata = {
    .jsonReadyValue = @"fbAppBridgeType_jsonReadyValue",
    .isBase64 = @"isBase64",
    .isPasteboard = @"isPasteboard",
    .tag = @"tag",
};

/*
 Used to identify what the original AppBridge type that was made JSON ready. It is used to
 be able to recreate it when asked to.
 */
static const struct {
    NSString *data;
    NSString *png;
} FBAppBridgeTypesTags = {
    .data = @"data",
    .png = @"png",
};

static NSString *const FBAppBridgeTypeIdentifier = @"com.facebook.Facebook.FBAppBridgeType";
static const NSUInteger PasteboardThreshold = 5120;

@implementation FBAppBridgeTypeToJSONConverter

@synthesize createdPasteboardNames = _createdPasteboardNames;

- (void)dealloc
{
    [_createdPasteboardNames release];
    [super dealloc];
}

- (NSDictionary *)jsonDictionaryFromDictionaryWithAppBridgeTypes:(NSDictionary *)dictionaryWithAppBridgeTypes {
    self.createdPasteboardNames = [NSMutableArray array];
  
    return [self convertedDictionaryFromDictionary:dictionaryWithAppBridgeTypes
                                  convertingToJSON:YES];
}

- (NSDictionary *)dictionaryWithAppBridgeTypesFromJSONDictionary:(NSDictionary *)jsonDictionary {
    return [self convertedDictionaryFromDictionary:jsonDictionary
                                  convertingToJSON:NO];
}

- (id)convertedObjectFromObject:(id)object convertingToJSON:(BOOL)convertingToJSON {
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)object;
        if (!convertingToJSON && dictionary[FBAppBridgeTypesMetadata.jsonReadyValue]) {
            return [FBAppBridgeTypeToJSONConverter appBridgeTypeFromJSON:dictionary];
        } else {
            return [self convertedDictionaryFromDictionary:dictionary
                                          convertingToJSON:convertingToJSON];
        }
    } else if ([object isKindOfClass:[NSArray class]]) {
        return [self convertedArrayFromArray:(NSArray *)object
                            convertingToJSON:convertingToJSON];
    } else if (convertingToJSON) {
        if ([object isKindOfClass:[NSData class]]) {
            return [self jsonFromData:(NSData *)object
                                  tag:FBAppBridgeTypesTags.data];
        } else if ([object isKindOfClass:[UIImage class]]) {
            UIImage *image = (UIImage *)object;
            return [self jsonFromData:UIImageJPEGRepresentation(image, [FBSettings defaultJPEGCompressionQuality])
                                  tag:FBAppBridgeTypesTags.png];
        }
    }
    
    // If we don't have special processing, return the same object
    return object;
}

- (NSDictionary *)convertedDictionaryFromDictionary:(NSDictionary *)dictionary
                                   convertingToJSON:(BOOL)convertingToJSON {
    NSArray *keys = [dictionary allKeys];
    if (!keys.count) {
        return dictionary;
    }
    NSMutableDictionary *convertedDictionary = [NSMutableDictionary dictionary];
    for (id key in keys) {
        id convertedObject = [self convertedObjectFromObject:dictionary[key]
                                            convertingToJSON:convertingToJSON];
        if (convertedObject) {
            convertedDictionary[key] = convertedObject;
        }
    }
    
    return convertedDictionary;
}

- (NSArray *)convertedArrayFromArray:(NSArray *)array convertingToJSON:(BOOL)convertingToJSON {
    int length = array.count;
    if (length == 0) {
        return array;
    }
    
    NSMutableArray *convertedArray = [NSMutableArray arrayWithCapacity:length];
    for (int i = 0; i < length; i++) {
        id convertedObject = [self convertedObjectFromObject:array[i]
                                            convertingToJSON:convertingToJSON];
        if (convertedObject) {
            convertedArray[i] = convertedObject;
        } else {
            convertedArray[i] = [NSNull null];
        }
    }
    
    return convertedArray;
}

- (NSMutableDictionary *)jsonFromData:(NSData *)data tag:(NSString *)tag {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    NSString *jsonReadyValue = nil;
    
    // If the data is large, put it in a UIPasteboard
    if (data.length > PasteboardThreshold) {
        NSString *uniqueSuffix = [[FBUtility newUUIDString] autorelease];
        NSString *pasteboardName = [FacebookSDKDomain stringByAppendingString:uniqueSuffix];
        UIPasteboard *board = [UIPasteboard pasteboardWithName:pasteboardName create:YES];
        if (board) {
            [board setPersistent:YES];
            [board setData:data forPasteboardType:FBAppBridgeTypeIdentifier];
            
            jsonReadyValue = board.name;
            [self.createdPasteboardNames addObject:board.name];
            
            json[FBAppBridgeTypesMetadata.isPasteboard] = [NSNumber numberWithBool:YES];
        }
    }
    
    // If a UIPasteboard was not (or could not be) used, put the data directly in the URL.
    if (!jsonReadyValue) {
        jsonReadyValue = FBEncodeBase64(data);
        json[FBAppBridgeTypesMetadata.isBase64] = [NSNumber numberWithBool:YES];
    }
    
    json[FBAppBridgeTypesMetadata.tag] = tag ?: @"";
    json[FBAppBridgeTypesMetadata.jsonReadyValue] = jsonReadyValue ?: @"";
    
    return json;
}

+ (id)appBridgeTypeFromJSON:(NSDictionary *)dictionary {
    NSString *jsonReadyValue = dictionary[FBAppBridgeTypesMetadata.jsonReadyValue];
    NSNumber *hasBase64 = dictionary[FBAppBridgeTypesMetadata.isBase64];
    NSNumber *hasPasteboard = dictionary[FBAppBridgeTypesMetadata.isPasteboard];
    id appBridgeType = nil;
    if (hasBase64) {
        appBridgeType = FBDecodeBase64(jsonReadyValue);
    } else if (hasPasteboard) {
        UIPasteboard *board = [UIPasteboard pasteboardWithName:jsonReadyValue create:NO];
        if (board) {
            appBridgeType = [board valueForPasteboardType:FBAppBridgeTypeIdentifier];
            [UIPasteboard removePasteboardWithName:board.name];
        }
    }
    
    if (appBridgeType && [dictionary[FBAppBridgeTypesMetadata.tag] isEqualToString:FBAppBridgeTypesTags.png]) {
        appBridgeType = [UIImage imageWithData:appBridgeType];
    }
    
    return appBridgeType;
}

@end
