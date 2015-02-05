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

typedef NS_OPTIONS(NSUInteger, FBAppEventsFeatureOptions) {
    FBAppEventsFeatureOptionsNone                      = 0,
    FBAppEventsFeatureOptionsShouldAccessAdvertisingID = 1 << 0,
    FBAppEventsFeatureOptionsLogImplicitPurchaseEvents = 1 << 1,
};

// Internal class holding server side Facebook app settings we fetch once from the
// server per process lifetime.

@interface FBFetchedAppSettings : NSObject

@property (copy, nonatomic) NSString *serverAppName;
@property (readwrite) BOOL supportsImplicitSdkLogging;
@property (readwrite) BOOL supportsSystemAuth;
@property (readwrite) BOOL enableLoginTooltip;
@property (readonly, nonatomic) NSString *appID;
@property (copy, nonatomic) NSString *loginTooltipContent;
@property (copy, nonatomic) NSDictionary *dialogConfigs;

- (instancetype)initWithAppID:(NSString *)appID
      appEventsFeatureOptions:(FBAppEventsFeatureOptions)appEventsFeatureOptions;

- (BOOL)shouldAccessAdvertisingID;
- (BOOL)doesAppLogImplicitPurchaseEvents;

@end
