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
 
#import "FBDataDiskCache.h"
#import "FBCacheIndex.h"
#import "FBAccessTokenData.h"

static const NSUInteger kMaxDataInMemorySize = 1 * 1024 * 1024; // 1MB
static const NSUInteger kMaxDiskCacheSize = 10 * 1024 * 1024; // 10MB

static NSString* const kDataDiskCachePath = @"DataDiskCache";
static NSString* const kCacheInfoFile = @"CacheInfo";
static NSString *const kAccessTokenKey = @"access_token";

@interface FBDataDiskCache() <FBCacheIndexFileDelegate>
@property (nonatomic, copy) NSString* dataCachePath;
@end

@implementation FBDataDiskCache

@synthesize dataCachePath = _dataCachePath;
@synthesize fileQueue = _fileQueue;

#pragma mark - Lifecycle

- (id)init 
{
    self = [super init];
    if (self) {
        NSArray* cacheList = NSSearchPathForDirectoriesInDomains(
            NSCachesDirectory, 
            NSUserDomainMask, 
            YES);
        
        NSString* cachePath = [cacheList objectAtIndex:0];
        _dataCachePath = 
            [[cachePath stringByAppendingPathComponent:kDataDiskCachePath] 
                copy];
        [[NSFileManager defaultManager] 
            createDirectoryAtPath:_dataCachePath 
            withIntermediateDirectories:YES 
            attributes:nil 
            error:nil];
        
        dispatch_queue_t bgPriQueue = 
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        _fileQueue = dispatch_queue_create(
            "File Cache Queue", 
            DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_fileQueue, bgPriQueue);
        
        _cacheIndex = [[FBCacheIndex alloc] initWithCacheFolder:_dataCachePath];
        _cacheIndex.diskCapacity = kMaxDiskCacheSize;
        _cacheIndex.delegate = self;

        _inMemoryCache = [[NSCache alloc] init];
        _inMemoryCache.totalCostLimit = kMaxDataInMemorySize;
    }
  
    return self;
}

- (void)dealloc 
{
    if (_fileQueue) {
        dispatch_release(_fileQueue);
    }

    [_cacheIndex release];
    [_dataCachePath release];
    [_inMemoryCache release];
    [super dealloc];
}

+ (FBDataDiskCache*)sharedCache
{
    static FBDataDiskCache* _instance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _instance = [[FBDataDiskCache alloc] init];
    });
  
    return _instance;
}

#pragma mark - Properties

- (NSUInteger)cacheSizeMemory
{
    return _inMemoryCache.totalCostLimit;
}

- (void)setCacheSizeMemory:(NSUInteger)cacheSizeMemory
{
    _inMemoryCache.totalCostLimit = cacheSizeMemory;
}

#pragma mark - FBCacheIndexFileDelegate

- (void) cacheIndex:(FBCacheIndex*)cacheIndex
    writeFileWithName:(NSString*)name 
    data:(NSData*)data
{
    NSString* filePath = [_dataCachePath stringByAppendingPathComponent:name];
    dispatch_async(_fileQueue, ^{
        [data writeToFile:filePath atomically:YES];
    });
}

- (void) cacheIndex:(FBCacheIndex*)cacheIndex
    deleteFileWithName:(NSString*)name
{
    NSString* filePath = [_dataCachePath stringByAppendingPathComponent:name];
    dispatch_async(_fileQueue, ^{
        [[NSFileManager defaultManager] 
            removeItemAtPath:filePath
            error:nil];
    });
}

#pragma mark - Other Methods

- (BOOL)_doesFileExist:(NSString*)name
{
    NSString* filePath = [_dataCachePath stringByAppendingPathComponent:name];
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

- (NSData*)dataForURL:(NSURL*)dataURL
{
    // TODO: Synchronize this across threads
    NSData* data = nil;
    @try {
        data = (NSData*)[_inMemoryCache objectForKey:dataURL];
        NSString* fileName = 
            [_cacheIndex fileNameForKey:dataURL.absoluteString];

        if (data == nil && fileName != nil) {
            // Not in-memory, on-disk only, read in
            if ([self _doesFileExist:fileName]) {
                NSString* cachePath = 
                    [_dataCachePath stringByAppendingPathComponent:fileName];

                data = [NSData
                    dataWithContentsOfFile:cachePath
                    options:NSDataReadingMappedAlways | NSDataReadingUncached  
                    error:nil];

                if (data) {
                    // It is possible that the file doesn't exist
                    [_inMemoryCache 
                        setObject:data 
                        forKey:dataURL 
                        cost:data.length];
                }
            }
        }
    } @catch (NSException* exception) {
        NSLog(@"FBDiskCache error: %@", exception.reason);
    } @finally {
        return data;
    }
}

- (void)removeDataForUrl:(NSURL*)url
{
    // TODO: Synchronize this across threads
    @try {
        [_inMemoryCache removeObjectForKey:url];
        [_cacheIndex removeEntryForKey:url.absoluteString];
    } @catch (NSException* exception) {
        NSLog(@"FBDiskCache error: %@", exception.reason);
    }
}

- (void)removeDataForSession:(FBSession*)session
{
    if (session == nil) {
        return;
    }
    
    // Here we are removing all cache entries that don't have session context
    // These are things like images and the like. The thorough way would
    // be to maintain refCounts of these entries associated with accessTokens
    // and use that to decide which images to delete. However, this might be
    // overkill for a cache. Maybe revisit later?
    [_cacheIndex removeEntries:kAccessTokenKey excludingFragment:YES];

    NSString* accessToken = session.accessTokenData.accessToken;
    if (accessToken != nil) {
        // Here we are removing all cache entries that have this session's access
        // token in the url.
        [_cacheIndex removeEntries:accessToken excludingFragment:NO];
    }
}

- (void)setData:(NSData*)data forURL:(NSURL*)url
{
    // TODO: Synchronize this across threads
    @try {
        [_cacheIndex 
            storeFileForKey:url.absoluteString 
            withData:data];

        [_inMemoryCache 
            setObject:data 
            forKey:url 
            cost:data.length];
    } @catch (NSException* exception) {
        NSLog(@"FBDiskCache error: %@", exception.reason);
    }
}

@end
