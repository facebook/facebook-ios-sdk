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
#import <sqlite3.h>

@class FBCacheIndex;

@protocol FBCacheIndexFileDelegate <NSObject>

@required
// Informs the disk cache to write contents to the specified file.  The callback
// should not block and should be executed in order.
- (void) cacheIndex:(FBCacheIndex*)cacheIndex
    writeFileWithName:(NSString*)name 
    data:(NSData*)data;
// Informs the disk cache to delete the specified file.
- (void) cacheIndex:(FBCacheIndex*)cacheIndex
    deleteFileWithName:(NSString*)name;

@end

@interface FBCacheIndex : NSObject
{
@private
    id <FBCacheIndexFileDelegate> _delegate;
    
    NSCache* _cachedEntries;
  
    NSUInteger _currentDiskUsage;
    NSUInteger _diskCapacity;
  
    sqlite3* _database;
    sqlite3_stmt* _insertStatement;
    sqlite3_stmt* _removeByKeyStatement;
    sqlite3_stmt* _selectByKeyStatement;
    sqlite3_stmt* _selectByKeyFragmentStatement;
    sqlite3_stmt* _selectExcludingKeyFragmentStatement;
    sqlite3_stmt* _trimStatement;
    sqlite3_stmt* _updateStatement;
  
    dispatch_queue_t _databaseQueue;
}

- (id)initWithCacheFolder:(NSString*)folderPath;

@property (assign) id delegate;
@property (nonatomic, readonly) NSUInteger currentDiskUsage;
@property (nonatomic, assign) NSUInteger diskCapacity;
@property (nonatomic, assign) NSUInteger entryCacheCountLimit;
@property (nonatomic, readonly) dispatch_queue_t databaseQueue;

- (NSString*)fileNameForKey:(NSString*)key;
- (NSString*)storeFileForKey:(NSString*)key withData:(NSData*)data;
- (void)removeEntryForKey:(NSString*)key;
- (void)removeEntries:(NSString*)keyFragment excludingFragment:(BOOL)exclude;

@end


