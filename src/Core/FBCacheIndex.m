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

#import "FBCacheIndex.h"

#import "FBDynamicFrameworkLoader.h"
#import "FBLogger.h"
#import "FBSettings.h"

#define CHECK_SQLITE(res, expectedResult, db) { \
int result = (res); \
if (result != expectedResult) { \
[FBLogger singleShotLogEntry:FBLoggingBehaviorCacheErrors formatString:@"FBCacheIndex: Expecting result %d, actual %d", \
expectedResult, \
result]; \
if (db) { \
[FBLogger singleShotLogEntry:FBLoggingBehaviorCacheErrors formatString:@"FBCacheIndex: SQLite error: %s", fbdfl_sqlite3_errmsg(db)]; \
} \
NSCAssert(NO, @""); \
} \
}

#define CHECK_SQLITE_SUCCESS(res, db) CHECK_SQLITE(res, SQLITE_OK, db)
#define CHECK_SQLITE_DONE(res, db) CHECK_SQLITE(res, SQLITE_DONE, db)

// Number of entries cached to memory
static const NSInteger kDefaultCacheCountLimit = 500;

static NSString *const cacheFilename = @"cache.db";
static const char *schema =
"CREATE TABLE IF NOT EXISTS cache_index "
"(uuid TEXT, key TEXT PRIMARY KEY, access_time REAL, file_size INTEGER)";

static const char *insertQuery =
"INSERT INTO cache_index VALUES (?, ?, ?, ?)";

static const char *updateQuery =
"UPDATE cache_index "
"SET uuid=?, access_time=?, file_size=? "
"WHERE key=?";

static const char *selectByKeyQuery =
"SELECT uuid, key, access_time, file_size FROM cache_index WHERE key = ?";

static const char *selectByKeyFragmentQuery =
"SELECT uuid, key, access_time, file_size FROM cache_index WHERE key LIKE ?";

static const char *selectExcludingKeyFragmentQuery =
"SELECT uuid, key, access_time, file_size FROM cache_index WHERE key NOT LIKE ?";

static const char *selectStorageSizeQuery =
"SELECT SUM(file_size) FROM cache_index";

static const char *deleteEntryQuery =
"DELETE FROM cache_index WHERE key=?";

static const char *trimQuery =
"CREATE TABLE trimmed AS "
"SELECT uuid, key, access_time, file_size, running_total "
"FROM ( "
"SELECT a1.uuid, a1.key, a1.access_time, "
"a1.file_size, SUM(a2.file_size) running_total "
"FROM cache_index a1, cache_index a2 "
"WHERE a1.access_time > a2.access_time OR "
"(a1.access_time = a2.access_time AND a1.uuid = a2.uuid) "
"GROUP BY a1.uuid ORDER BY a1.access_time) rt "
"WHERE rt.running_total <= ?";

#pragma mark - C Helpers

static void initializeStatement(
                                sqlite3 *database,
                                sqlite3_stmt **statement,
                                const char *statementText)
{
    if (*statement == nil) {
        CHECK_SQLITE_SUCCESS(
                             fbdfl_sqlite3_prepare_v2(database, statementText, -1, statement, nil),
                             database
                             );
    } else {
        CHECK_SQLITE_SUCCESS(fbdfl_sqlite3_reset(*statement), database);
    }
}

static void releaseStatement(sqlite3_stmt *statement, sqlite3 *database)
{
    if (statement != nil) {
        CHECK_SQLITE_SUCCESS(fbdfl_sqlite3_finalize(statement), database);
    }
}

@interface FBCacheEntityInfo : NSObject
{
@private
    NSString *_uuid;
    NSString *_key;
    CFTimeInterval _accessTime;
    NSUInteger _fileSize;
    BOOL _dirty;
}

- (instancetype)initWithKey:(NSString *)key
                       uuid:(NSString *)uuid
                 accessTime:(CFTimeInterval)accessTime
                   fileSize:(NSUInteger)fileSize;

@property (copy, readonly) NSString *key;
@property (copy, readonly) NSString *uuid;
@property (assign, readonly) CFTimeInterval accessTime;
@property (assign, readonly) NSUInteger fileSize;
@property (assign, getter = isDirty) BOOL dirty;

- (void)registerAccess;

@end

@interface FBCacheIndex () <NSCacheDelegate>

- (FBCacheEntityInfo *)_entryForKey:(NSString *)key;
- (void)_fetchCurrentDiskUsage;
- (FBCacheEntityInfo *)_readEntryFromDatabase:(NSString *)key;
- (NSMutableArray *)_readEntriesFromDatabase:(NSString *)keyFragment excludingFragment:(BOOL)exclude;
- (FBCacheEntityInfo *)_createCacheEntityInfo:(sqlite3_stmt *)selectStatement;
- (void)_removeEntryFromDatabaseForKey:(NSString *)key;
- (void)_trimDatabase;
- (void)_updateEntryInDatabaseForKey:(NSString *)key
                               entry:(FBCacheEntityInfo *)entry;
- (void)_writeEntryInDatabase:(FBCacheEntityInfo *)entry;

@end

@implementation FBCacheIndex

#pragma mark - Lifecycle

- (instancetype)initWithCacheFolder:(NSString *)folderPath
{
    self = [super init];
    if (self) {
        NSString *cacheDBFullPath =
        [folderPath stringByAppendingPathComponent:cacheFilename];

        dispatch_queue_t lowPriQueue =
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        _databaseQueue = dispatch_queue_create(
                                               "Data Cache queue",
                                               DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_databaseQueue, lowPriQueue);

        __block BOOL success = YES;

        // TODO: This is really bad if higher layers are going to be
        // multi-threaded.  And this has to be unblocked.
        dispatch_sync(
                      _databaseQueue,
                      ^{
                          success = (fbdfl_sqlite3_open_v2(
                                                           cacheDBFullPath.UTF8String,
                                                           &_database,
                                                           SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
                                                           nil) == SQLITE_OK);

                          if (success) {
                              success = (fbdfl_sqlite3_exec(
                                                            _database,
                                                            schema,
                                                            nil,
                                                            nil,
                                                            nil) == SQLITE_OK);
                          }
                      }
                      );

        if (!success) {
            [self release];
            return nil;
        }

        // Get disk usage asynchronously
        dispatch_async(_databaseQueue, ^{
            [self _fetchCurrentDiskUsage];
        });

        _cachedEntries = [[NSCache alloc] init];
        _cachedEntries.delegate = self;
        _cachedEntries.countLimit = kDefaultCacheCountLimit;
    }

    return self;
}

- (void)dealloc {
    if (_databaseQueue) {
        // Copy these locally so we don't capture self in the block
        sqlite3 *const db = _database;
        sqlite3_stmt *const is = _insertStatement;
        sqlite3_stmt *const sbks = _selectByKeyStatement;
        sqlite3_stmt *const sbkfs = _selectByKeyFragmentStatement;
        sqlite3_stmt *const sekfs = _selectExcludingKeyFragmentStatement;
        sqlite3_stmt *const rbks = _removeByKeyStatement;
        sqlite3_stmt *const ts = _trimStatement;
        sqlite3_stmt *const us = _updateStatement;
        dispatch_async(_databaseQueue, ^{
            releaseStatement(is, nil);
            releaseStatement(sbks, nil);
            releaseStatement(sbkfs, nil);
            releaseStatement(sekfs, nil);
            releaseStatement(rbks, nil);
            releaseStatement(ts, nil);
            releaseStatement(us, nil);

            CHECK_SQLITE_SUCCESS(fbdfl_sqlite3_close(db), nil);
        });

        dispatch_release(_databaseQueue);
    }

    _cachedEntries.delegate = nil;
    [_cachedEntries release];
    [super dealloc];
}

#pragma mark - Properties

- (NSUInteger)entryCacheCountLimit
{
    return _cachedEntries.countLimit;
}

- (void)setEntryCacheCountLimit:(NSUInteger)entryCacheCountLimit
{
    _cachedEntries.countLimit = entryCacheCountLimit;
}

#pragma mark - Public

- (NSString *)fileNameForKey:(NSString *)key
{
    FBCacheEntityInfo *entryInfo = [self _entryForKey:key];
    [entryInfo registerAccess];
    if (entryInfo) {
        return [[entryInfo.uuid retain] autorelease];
    } else {
        return nil;
    }
}

- (NSString *)storeFileForKey:(NSString *)key withData:(NSData *)data
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString =
    (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);

    CFRelease(uuid);
    FBCacheEntityInfo *entry = [[FBCacheEntityInfo alloc]
                                initWithKey:key
                                uuid:uuidString
                                accessTime:0
                                fileSize:data.length];

    [entry registerAccess];
    dispatch_async(_databaseQueue, ^{
        [self _writeEntryInDatabase:entry];

        _currentDiskUsage += data.length;
        if (_currentDiskUsage > _diskCapacity) {
            [self _trimDatabase];
        }
    });

    [self.delegate cacheIndex:self writeFileWithName:uuidString data:data];

    [_cachedEntries setObject:entry forKey:key];
    [entry release];

    return [uuidString autorelease];
}

- (void)removeEntryForKey:(NSString *)key
{
    FBCacheEntityInfo *entry = [self _entryForKey:key];
    entry.dirty = NO; // Removing, so no need to flush to disk

    NSInteger spaceSaved = entry.fileSize;
    [_cachedEntries removeObjectForKey:key];

    dispatch_async(_databaseQueue, ^{
        [self _removeEntryFromDatabaseForKey:key];
        if (_currentDiskUsage >= spaceSaved) {
            _currentDiskUsage -= spaceSaved;
        } else {
            NSCAssert(NO, @"Our disk usage is out of whack");
            // This means current disk usage is out of whack - let's re-read
            [self _fetchCurrentDiskUsage];
        };

        [self.delegate cacheIndex:self deleteFileWithName:entry.uuid];
    });
}

- (void)removeEntries:(NSString *)keyFragment excludingFragment:(BOOL)exclude
{
    if (keyFragment == nil) {
        return;
    }

    __block NSMutableArray *entries;

    dispatch_sync(_databaseQueue, ^{
        entries = [self _readEntriesFromDatabase:keyFragment excludingFragment:exclude];
    });

    for (FBCacheEntityInfo *entry in entries) {
        if ([_cachedEntries objectForKey:entry.key] == nil) {
            // Adding to the cache since the call to removeEntryForKey will look for the entry and
            // try to retrieve it from the DB which will in turn add it to the cache anyways. So
            // pre-emptively adding it to the in memory cache saves some DB roundtrips.
            //
            // This is only done for NSCache entries that don't already exist since replacing the
            // old one with the new one will trigger willEvictObject which will try and perform
            // a DB write. Since the write is async, we might end up in a weird state.
            [_cachedEntries setObject:entry forKey:entry.key];
        }

        [self removeEntryForKey:entry.key];
    }
}

#pragma mark - NSCache delegate

- (void)cache:(NSCache *)cache willEvictObject:(id)obj
{
    FBCacheEntityInfo *entryInfo = (FBCacheEntityInfo *)obj;
    if (entryInfo.dirty) {
        dispatch_async(_databaseQueue, ^{
            [self _writeEntryInDatabase:entryInfo];
        });
    }
}

#pragma mark - Private

- (void)_updateEntryInDatabaseForKey:(NSString *)key
                               entry:(FBCacheEntityInfo *)entry
{
    initializeStatement(_database, &_updateStatement, updateQuery);

    CHECK_SQLITE_SUCCESS(fbdfl_sqlite3_bind_text(
                                                 _updateStatement,
                                                 1,
                                                 entry.uuid.UTF8String,
                                                 (int)entry.uuid.length,
                                                 nil), _database);

    CHECK_SQLITE_SUCCESS(fbdfl_sqlite3_bind_double(
                                                   _updateStatement,
                                                   2,
                                                   entry.accessTime), _database);

    NSAssert(entry.fileSize <= INT_MAX, @"");
    CHECK_SQLITE_SUCCESS(fbdfl_sqlite3_bind_int(
                                                _updateStatement,
                                                3,
                                                (int)entry.fileSize), _database);

    CHECK_SQLITE_SUCCESS(fbdfl_sqlite3_bind_text(
                                                 _updateStatement,
                                                 4,
                                                 entry.key.UTF8String,
                                                 (int)entry.key.length,
                                                 nil), _database);

    CHECK_SQLITE_DONE(fbdfl_sqlite3_step(_updateStatement), _database);

    entry.dirty = NO;
}

- (void)_writeEntryInDatabase:(FBCacheEntityInfo *)entry
{
    FBCacheEntityInfo *existing = [self _readEntryFromDatabase:entry.key];
    if (existing) {

        // Entry already exists - update the entry
        [self _updateEntryInDatabaseForKey:existing.key
                                     entry:entry];

        if (![existing.uuid isEqualToString:entry.uuid]) {
            // The files have changed.  Schedule a delete for existing file
            [self.delegate cacheIndex:self deleteFileWithName:existing.uuid];
        }
        return;
    }

    initializeStatement(_database, &_insertStatement, insertQuery);
    CHECK_SQLITE_SUCCESS(fbdfl_sqlite3_bind_text(
                                                 _insertStatement,
                                                 1,
                                                 entry.uuid.UTF8String,
                                                 (int)entry.uuid.length,
                                                 nil), _database);

    CHECK_SQLITE_SUCCESS(fbdfl_sqlite3_bind_text(
                                                 _insertStatement,
                                                 2,
                                                 entry.key.UTF8String,
                                                 (int)entry.key.length,
                                                 nil), _database);

    CHECK_SQLITE_SUCCESS(fbdfl_sqlite3_bind_double(
                                                   _insertStatement,
                                                   3,
                                                   entry.accessTime), _database);

    NSAssert(entry.fileSize <= INT_MAX, @"");
    CHECK_SQLITE_SUCCESS(fbdfl_sqlite3_bind_int(
                                                _insertStatement,
                                                4,
                                                (int)entry.fileSize), _database);

    CHECK_SQLITE_DONE(fbdfl_sqlite3_step(_insertStatement), _database);

    entry.dirty = NO;
}

- (FBCacheEntityInfo *)_readEntryFromDatabase:(NSString *)key
{
    initializeStatement(_database, &_selectByKeyStatement, selectByKeyQuery);

    CHECK_SQLITE_SUCCESS(fbdfl_sqlite3_bind_text(
                                                 _selectByKeyStatement,
                                                 1,
                                                 key.UTF8String,
                                                 (int)key.length,
                                                 nil), _database);

    return [self _createCacheEntityInfo:_selectByKeyStatement];
}

- (NSMutableArray *)_readEntriesFromDatabase:(NSString *)keyFragment
                           excludingFragment:(BOOL)exclude
{
    sqlite3_stmt *selectStatement;
    const char *query;
    if (exclude) {
        selectStatement = _selectExcludingKeyFragmentStatement;
        query = selectExcludingKeyFragmentQuery;
    } else {
        selectStatement = _selectByKeyFragmentStatement;
        query = selectByKeyFragmentQuery;
    }

    initializeStatement(_database, &selectStatement, query);
    NSString *wildcardKeyFragment = [NSString stringWithFormat:@"%%%@%%", keyFragment];

    CHECK_SQLITE_SUCCESS(fbdfl_sqlite3_bind_text(
                                                 selectStatement,
                                                 1,
                                                 wildcardKeyFragment.UTF8String,
                                                 (int)wildcardKeyFragment.length,
                                                 nil), _database);

    NSMutableArray *entries = [[[NSMutableArray alloc] init] autorelease];
    FBCacheEntityInfo *entry;

    while ((entry = [self _createCacheEntityInfo:selectStatement]) != nil) {
        [entries addObject:entry];
    }

    return entries;
}

- (FBCacheEntityInfo *)_createCacheEntityInfo:(sqlite3_stmt *)selectStatement
{
    int result = fbdfl_sqlite3_step(selectStatement);
    if (result != SQLITE_ROW) {
        return nil;
    }

    const unsigned char *uuidStr =
    fbdfl_sqlite3_column_text(selectStatement, 0);
    const unsigned char *key =
    fbdfl_sqlite3_column_text(selectStatement, 1);
    CFTimeInterval accessTime =
    fbdfl_sqlite3_column_double(selectStatement, 2);
    NSUInteger fileSize = fbdfl_sqlite3_column_int(selectStatement, 3);

    FBCacheEntityInfo *entry = [[FBCacheEntityInfo alloc]
                                initWithKey:[NSString
                                             stringWithCString:(const char *)key
                                             encoding:NSUTF8StringEncoding]
                                uuid:[NSString
                                      stringWithCString:(const char *)uuidStr
                                      encoding:NSUTF8StringEncoding]
                                accessTime:accessTime
                                fileSize:fileSize];
    return [entry autorelease];
}

- (void)_fetchCurrentDiskUsage
{
    sqlite3_stmt *sizeStatement = nil;
    initializeStatement(_database, &sizeStatement, selectStorageSizeQuery);

    CHECK_SQLITE(fbdfl_sqlite3_step(sizeStatement), SQLITE_ROW, _database);
    _currentDiskUsage = fbdfl_sqlite3_column_int(sizeStatement, 0);
    releaseStatement(sizeStatement, _database);
}

- (FBCacheEntityInfo *)_entryForKey:(NSString *)key
{
    __block FBCacheEntityInfo *entryInfo = [_cachedEntries objectForKey:key];
    if (entryInfo == nil) {
        // TODO: This is really bad if higher layers are going to be
        // multi-threaded.  And this has to be unblocked.
        dispatch_sync(_databaseQueue, ^{
            entryInfo = [self _readEntryFromDatabase:key];
        });

        if (entryInfo) {
            [_cachedEntries setObject:entryInfo forKey:key];
        }
    }

    return entryInfo;
}

- (void)_removeEntryFromDatabaseForKey:(NSString *)key
{
    initializeStatement(_database, &_removeByKeyStatement, deleteEntryQuery);
    CHECK_SQLITE_SUCCESS(fbdfl_sqlite3_bind_text(
                                                 _removeByKeyStatement,
                                                 1,
                                                 key.UTF8String,
                                                 (int)key.length,
                                                 nil), _database);

    CHECK_SQLITE_DONE(fbdfl_sqlite3_step(_removeByKeyStatement), _database);
}

- (void)_dropTrimmingTable
{
    sqlite3_stmt *trimCleanStatement = nil;

    static const char *trimDropQuery = "DROP TABLE IF EXISTS trimmed";
    initializeStatement(_database, &trimCleanStatement, trimDropQuery);

    CHECK_SQLITE_DONE(fbdfl_sqlite3_step(trimCleanStatement), _database);
    releaseStatement(trimCleanStatement, _database);
}

- (void)_flushOrphanedFiles
{
    // TODO: #1001434
}

// Trimming of cache entries based on LRU eviction policy.
// All the computations are done at the DB level, as follows:
// - create a temporary table 'trimmed', which computes which records need
//   purging, based on access time and running total of file size
// - iterate over 'trimmed', clear in-memory cache, queue data files for
//   deletion on a background queue
// - batch-remove these entries from the index
// - drop the temporary 'trimmed' table.
- (void)_trimDatabase
{
    NSAssert(_currentDiskUsage > _diskCapacity, @"");
    if (_currentDiskUsage <= _diskCapacity) {
        return;
    }

    [self _dropTrimmingTable];
    initializeStatement(_database, &_trimStatement, trimQuery);
    CHECK_SQLITE_SUCCESS(fbdfl_sqlite3_bind_int(
                                                _trimStatement,
                                                1,
                                                _currentDiskUsage - _diskCapacity * 0.8), _database);

    CHECK_SQLITE_DONE(fbdfl_sqlite3_step(_trimStatement), _database);

    // Need to re-prep this statement as it's bound to the temporary table
    // and can be stored between trims
    static const char *trimSelectQuery =
    "SELECT uuid, key, file_size FROM trimmed";

    sqlite3_stmt *trimSelectStatement = nil;
    initializeStatement(
                        _database,
                        &trimSelectStatement,
                        trimSelectQuery);

    NSUInteger spaceCleaned = 0;
    while (fbdfl_sqlite3_step(trimSelectStatement) == SQLITE_ROW) {
        const unsigned char *uuidStr =
        fbdfl_sqlite3_column_text(trimSelectStatement, 0);
        const unsigned char *keyStr =
        fbdfl_sqlite3_column_text(trimSelectStatement, 1);
        spaceCleaned += fbdfl_sqlite3_column_int(trimSelectStatement, 2);

        // Remove in-memory cache entry if present
        NSString *key = [NSString
                         stringWithCString:(const char *)keyStr
                         encoding:NSUTF8StringEncoding];

        NSString *uuid = [NSString
                          stringWithCString:(const char *)uuidStr
                          encoding:NSUTF8StringEncoding];

        FBCacheEntityInfo *entry = [_cachedEntries objectForKey:key];
        entry.dirty = NO;
        [_cachedEntries removeObjectForKey:key];

        // Delete the file
        [self.delegate cacheIndex:self deleteFileWithName:uuid];
    }

    releaseStatement(trimSelectStatement, _database);

    // Batch remove statement
    sqlite3_stmt *trimCleanStatement = nil;
    static const char *trimCleanQuery =
    "DELETE FROM cache_index WHERE key IN (SELECT key from trimmed)";

    initializeStatement(_database, &trimCleanStatement, trimCleanQuery);
    CHECK_SQLITE_DONE(fbdfl_sqlite3_step(trimCleanStatement), _database);

    releaseStatement(trimCleanStatement, _database);
    trimCleanStatement = nil;

    _currentDiskUsage -= spaceCleaned;
    NSAssert(_currentDiskUsage <= _diskCapacity, @"");

    // Okay to drop the trimming table
    [self _dropTrimmingTable];
    [self _flushOrphanedFiles];
}

@end

@implementation FBCacheEntityInfo

#pragma mark - Lifecycle

- (instancetype)initWithKey:(NSString *)key
                       uuid:(NSString *)uuid
                 accessTime:(CFTimeInterval)accessTime
                   fileSize:(NSUInteger)fileSize
{
    self = [super init];
    if (self != nil) {
        _key = [key copy];
        _uuid = [uuid copy];
        _accessTime = accessTime;
        _fileSize = fileSize;
    }

    return self;
}

- (void)dealloc {
    [_uuid release];
    [_key release];
    [super dealloc];
}

- (void)registerAccess
{
    _accessTime = CFAbsoluteTimeGetCurrent();
    _dirty = YES;
}

@end
