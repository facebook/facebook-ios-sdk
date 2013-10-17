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

@interface FBAppBridgeTypeToJSONConverter : NSObject

/*!
 @abstract
 Following a call to jsonDictionaryFromDictionaryWithAppBridgeTypes:, this property
 will contain the names of any items that were put on the pasteboard.
 */
@property (nonatomic, retain) NSMutableArray *createdPasteboardNames;

/*!
 @abstract
 Call this method to convert a dictionary containing types that are not supported by JSON, but are
 supported by FBAppBridge to a dictionary that can be safely serialized to JSON

 @param dictionaryWithAppBridgeTypes An NSDictionary that contains types supported by FBAppBridge, either
 as direct descendents or further nested in dictionaries and arrays.

 @return A dictionary that is ready for JSON serialization
 */
- (NSDictionary *)jsonDictionaryFromDictionaryWithAppBridgeTypes:(NSDictionary *)dictionaryWithAppBridgeTypes;

/*!
 @abstract
 Call this method to retrieve a copy of the original dictionary that was converted to be JSON
 serializable via a call to jsonDictionaryFromDictionaryWithAppBridgeTypes:

 @param jsonDictionary An object that was previously processed via a call to
 jsonDictionaryFromDictionaryWithAppBridgeTypes:

 @return An object that is in the state prior to the call to wrap:
 */
- (NSDictionary *)dictionaryWithAppBridgeTypesFromJSONDictionary:(NSDictionary *)jsonDictionary;

@end
