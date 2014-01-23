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

#import "FBDialogsParams.h"

@interface FBDialogsParams ()

/*!
 @abstract
 This method is abstract and must be defined by all classes that derive from `FBDialogParams`
 */
- (NSDictionary *)dictionaryMethodArgs;

/*!
 @abstract
 This method is abstract and must be defined by all classes that derive from 'FBDialogParams'.
 It validates the parameters and returns the app bridge version they should be used on.
 */
- (NSString *)appBridgeVersion;

- (NSError *)validate;

@end
