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

#import "FBRequestConnection.h"
#import "FBRequestMetadata.h"
#import "FBSDKMacros.h"

@class FBRequestConnectionRetryManager;

FBSDK_EXTERN NSString *const kApiURLPrefix;

@interface FBRequestConnection (Internal)

@property (nonatomic, readonly) BOOL isResultFromCache;
@property (nonatomic, readonly) NSMutableArray *requests;
@property (nonatomic, readonly) FBRequestConnectionRetryManager *retryManager;

- (instancetype)initWithMetadata:(NSArray *)metadataArray;

- (void)startWithCacheIdentity:(NSString *)cacheIdentity
         skipRoundtripIfCached:(BOOL)consultCache;

- (FBRequestMetadata *)getRequestMetadata:(FBRequest *)request;

// for testing
- (NSString *)urlStringForSingleRequest:(FBRequest *)request forBatch:(BOOL)forBatch;

- (NSString *)accessTokenWithRequest:(FBRequest *)request;

@end
