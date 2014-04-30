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

#import "FBAppBridge.h"

@class FBLinkShareParams;
@class FBOpenGraphActionParams;

@interface FBAppBridgeScheme : NSObject

@property (nonatomic, copy) NSString *version;

// Notably these can return nil if no valid scheme was found for the device (i.e,. related app is not installed).
+ (instancetype)bridgeSchemeForFBAppForShareDialogParams:(FBLinkShareParams *)params;
+ (instancetype)bridgeSchemeForFBAppForShareDialogPhotos;
+ (instancetype)bridgeSchemeForFBAppForOpenGraphActionShareDialogParams:(FBOpenGraphActionParams *)params;
+ (instancetype)bridgeSchemeForFBAppForLike;
+ (instancetype)bridgeSchemeForFBMessengerForShareDialogParams:(FBLinkShareParams *)params;
+ (instancetype)bridgeSchemeForFBMessengerForShareDialogPhotos;
+ (instancetype)bridgeSchemeForFBMessengerForOpenGraphActionShareDialogParams:(FBOpenGraphActionParams *)params;


+ (BOOL)isSupportedScheme:(NSString *)scheme;
- (NSURL *)urlForMethod:(NSString *)method queryParams:(NSDictionary *)queryParams;

@end
