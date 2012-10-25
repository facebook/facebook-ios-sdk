/*
 * Copyright 2010 Facebook
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
#import <UIKit/UIKit.h>
#import "FBSession.h"

@class FBCacheIndex;

// This is a Disk based cache used internally by Facebook SDK
@interface FBDataDiskCache : NSObject
{
@private
    NSCache* _inMemoryCache;
    FBCacheIndex* _cacheIndex;
    NSString* _dataCachePath;
  
    dispatch_queue_t _fileQueue;
}

+ (FBDataDiskCache*)sharedCache;

@property (nonatomic, assign) NSUInteger cacheSizeMemory;
@property (nonatomic, readonly) dispatch_queue_t fileQueue;

- (NSData*)dataForURL:(NSURL*)dataURL;
- (void)setData:(NSData*)data forURL:(NSURL*)url;
- (void)removeDataForUrl:(NSURL*)url;
- (void)removeDataForSession:(FBSession*)session;

@end
