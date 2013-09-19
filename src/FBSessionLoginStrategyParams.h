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

#import "FacebookSDK.h"

@interface FBSessionLoginStrategyParams : NSObject

@property BOOL tryIntegratedAuth;
@property BOOL tryFBAppAuth;
@property BOOL trySafariAuth;
@property BOOL tryFallback;
@property BOOL isReauthorize;
@property FBSessionDefaultAudience defaultAudience;
@property (retain, nonatomic) NSArray *permissions;
@property BOOL canFetchAppSettings;
@property (retain, nonatomic) NSMutableDictionary *webParams;

@end
