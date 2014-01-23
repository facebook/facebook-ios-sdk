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

#import "FBDynamicFrameworkLoader.h"

#import <dlfcn.h>

#import "FBLogger.h"
#import "FBSettings.h"

static dispatch_once_t g_dispatchTokenLibrary;
static dispatch_once_t g_dispatchTokenSymbol;
static NSMutableDictionary *g_libraryMap = nil;
static NSMutableDictionary *g_symbolMap = nil;

static void *openLibrary(NSString *libraryPath) {
    if (!g_libraryMap) {
        dispatch_once(&g_dispatchTokenLibrary, ^{
            g_libraryMap = [[NSMutableDictionary alloc] init];
        });
    }
    id cachedHandle = [g_libraryMap objectForKey:libraryPath];
    if (cachedHandle) {
        return [cachedHandle pointerValue];
    }
    void *handle = dlopen([libraryPath fileSystemRepresentation], RTLD_LAZY);
    if (handle) {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorInformational formatString:@"Dynamically loaded library at %@", libraryPath];
    } else {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorInformational formatString:@"Failed to load library at %@", libraryPath];
    }
    [g_libraryMap setObject:[NSValue valueWithPointer:handle] forKey:libraryPath];
    return handle;
}

static void * loadSymbol(NSString *libraryPath, NSString *symbolName) {
    if (!g_symbolMap) {
        dispatch_once(&g_dispatchTokenSymbol, ^{
            g_symbolMap = [[NSMutableDictionary alloc] init];
        });
    }
    NSString *key = [NSString stringWithFormat:@"%@:%@", libraryPath, symbolName];
    id cachedHandle = [g_symbolMap objectForKey:key];
    if (cachedHandle) {
        return [cachedHandle pointerValue];
    }
    void *handle = openLibrary(libraryPath);
    void *symbol = dlsym(handle, [symbolName cStringUsingEncoding:NSASCIIStringEncoding]);
    [g_symbolMap setObject:[NSValue valueWithPointer:symbol] forKey:key];
    return symbol;
}

static NSString *buildFrameworkPath(NSString *framework) {
    NSString *path = [NSString stringWithFormat:[FBDynamicFrameworkLoader frameworkPathTemplate], framework, framework];
    return path;
}

@implementation FBDynamicFrameworkLoader

static NSString *g_frameworkPathTemplate = @"/System/Library/Frameworks/%@.framework/%@";
static NSString *g_sqlitePath = @"/usr/lib/libsqlite3.dylib";

+ (Class)loadClass:(NSString *)className withFramework:(NSString *)frameworkName {
    NSString *symbolName = [NSString stringWithFormat:@"OBJC_CLASS_$_%@", className];
    void * symbol = [self loadSymbol:symbolName withFramework:frameworkName];
    Class c = (Class)symbol;
    return c;
}

+ (NSString *)loadStringConstant:(NSString *)constantName withFramework:(NSString *)frameworkName {
    void *symbol = [self loadSymbol:constantName withFramework:frameworkName];
    NSAssert2((symbol != nil), @"Attempt to load symbol %@ in the %@ framework but this failed, likely a misspelling or the framework is not available on the version of the OS", constantName, frameworkName);
    NSString * s = *(NSString **)symbol;
    NSAssert1([s isKindOfClass:[NSString class]], @"Loaded symbol %@ is not of type NSString *", constantName);
    return s;
}

+ (SecRandomRef) loadkSecRandomDefault {
    void * symbol = [self loadSymbol:@"kSecRandomDefault" withFramework:@"Security"];
    NSAssert((symbol != nil), @"Failed to load symbol kSecRandomDefault in the Security framework");
    SecRandomRef ref = *(SecRandomRef *)symbol;
    return ref;
}

+ (void *)loadSymbol:(NSString *)symbol withFramework:(NSString *)framework {
    return loadSymbol(buildFrameworkPath(framework), symbol);
}

+ (NSString *)frameworkPathTemplate {
    return g_frameworkPathTemplate;
}

+ (void)setFrameworkPathTemplate:(NSString *)pathTemplate {
    [pathTemplate retain];
    [g_frameworkPathTemplate release];
    g_frameworkPathTemplate = pathTemplate;
}

+ (NSString *)sqlitePath {
    return g_sqlitePath;
}

+ (void)setSqlitePath:(NSString *)path {
    [path retain];
    [g_sqlitePath release];
    g_sqlitePath = path;
}

@end


// Security APIs
typedef int (*SecRandomCopyBytesFuncType)(SecRandomRef, size_t, uint8_t*);

int fbdfl_SecRandomCopyBytes(SecRandomRef rnd, size_t count, uint8_t *bytes) {
    NSString *handle = buildFrameworkPath(@"Security");
    SecRandomCopyBytesFuncType f = (SecRandomCopyBytesFuncType)loadSymbol(handle, @"SecRandomCopyBytes");
    return f(rnd, count, bytes);
}

// SQLITE3 APIs
void *loadSqliteSymbol(NSString *symbol) {
    return loadSymbol([FBDynamicFrameworkLoader sqlitePath], symbol);
}

typedef SQLITE_API const char *(*sqlite3_errmsg_type)(sqlite3*);
typedef SQLITE_API int (*sqlite3_prepare_v2_type)(sqlite3*, const char *, int, sqlite3_stmt **, const char **);
typedef SQLITE_API int (*sqlite3_reset_type)(sqlite3_stmt*);
typedef SQLITE_API int (*sqlite3_finalize_type)(sqlite3_stmt*);
typedef SQLITE_API int (*sqlite3_open_v2_type)(const char*, sqlite3**, int, const char*);
typedef SQLITE_API int (*sqlite3_exec_type)(sqlite3*, const char*, int (*)(void*,int,char**,char**), void*, char**);
typedef SQLITE_API int (*sqlite3_close_type)(sqlite3*);
typedef SQLITE_API int (*sqlite3_bind_double_type)(sqlite3_stmt*, int, double);
typedef SQLITE_API int (*sqlite3_bind_int_type)(sqlite3_stmt*, int, int);
typedef SQLITE_API int (*sqlite3_bind_text_type)(sqlite3_stmt*, int, const char*, int, void(*)(void*));
typedef SQLITE_API int (*sqlite3_step_type)(sqlite3_stmt*);
typedef SQLITE_API double (*sqlite3_column_double_type)(sqlite3_stmt*, int);
typedef SQLITE_API int (*sqlite3_column_int_type)(sqlite3_stmt*, int);
typedef SQLITE_API const unsigned char *(*sqlite3_column_text_type)(sqlite3_stmt*, int);

SQLITE_API const char *fbdfl_sqlite3_errmsg(sqlite3 *db) {
    sqlite3_errmsg_type f = (sqlite3_errmsg_type)loadSqliteSymbol(@"sqlite3_errmsg");
    return f(db);
}

SQLITE_API int fbdfl_sqlite3_prepare_v2(sqlite3 *db, const char *zSql, int nByte, sqlite3_stmt **ppStmt, const char **pzTail) {
    sqlite3_prepare_v2_type f = (sqlite3_prepare_v2_type)loadSqliteSymbol(@"sqlite3_prepare_v2");
    return f(db, zSql, nByte, ppStmt, pzTail);
}

SQLITE_API int fbdfl_sqlite3_reset(sqlite3_stmt *pStmt) {
    sqlite3_reset_type f = (sqlite3_reset_type)loadSqliteSymbol(@"sqlite3_reset");
    return f(pStmt);
}

SQLITE_API int fbdfl_sqlite3_finalize(sqlite3_stmt *pStmt) {
    sqlite3_finalize_type f = (sqlite3_finalize_type)loadSqliteSymbol(@"sqlite3_finalize");
    return f(pStmt);
}

SQLITE_API int fbdfl_sqlite3_open_v2(const char *filename, sqlite3 **ppDb, int flags, const char *zVfs) {
    sqlite3_open_v2_type f = (sqlite3_open_v2_type)loadSqliteSymbol(@"sqlite3_open_v2");
    return f(filename, ppDb, flags, zVfs);
}

SQLITE_API int fbdfl_sqlite3_exec(sqlite3 *db, const char *sql, int (*callback)(void*,int,char**,char**), void * arg, char **errmsg) {
    sqlite3_exec_type f = (sqlite3_exec_type)loadSqliteSymbol(@"sqlite3_exec");
    return f(db, sql, callback, arg, errmsg);
}

SQLITE_API int fbdfl_sqlite3_close(sqlite3 *db) {
    sqlite3_close_type f = (sqlite3_close_type)loadSqliteSymbol(@"sqlite3_close");
    return f(db);
}

SQLITE_API int fbdfl_sqlite3_bind_double(sqlite3_stmt *stmt, int index , double value) {
    sqlite3_bind_double_type f = (sqlite3_bind_double_type)loadSqliteSymbol(@"sqlite3_bind_double");
    return f(stmt, index, value);
}

SQLITE_API int fbdfl_sqlite3_bind_int(sqlite3_stmt *stmt, int index, int value) {
    sqlite3_bind_int_type f = (sqlite3_bind_int_type)loadSqliteSymbol(@"sqlite3_bind_int");
    return f(stmt, index, value);
}

SQLITE_API int fbdfl_sqlite3_bind_text(sqlite3_stmt *stmt, int index, const char* value, int n, void(*callback)(void*)) {
    sqlite3_bind_text_type f = (sqlite3_bind_text_type)loadSqliteSymbol(@"sqlite3_bind_text");
    return f(stmt, index, value, n, callback);
}

SQLITE_API int fbdfl_sqlite3_step(sqlite3_stmt *stmt) {
    sqlite3_step_type f = (sqlite3_step_type)loadSqliteSymbol(@"sqlite3_step");
    return f(stmt);
}

SQLITE_API double fbdfl_sqlite3_column_double(sqlite3_stmt *stmt, int iCol) {
    sqlite3_column_double_type f = (sqlite3_column_double_type)loadSqliteSymbol(@"sqlite3_column_double");
    return f(stmt, iCol);
}

SQLITE_API int fbdfl_sqlite3_column_int(sqlite3_stmt *stmt, int iCol) {
    sqlite3_column_int_type f = (sqlite3_column_int_type)loadSqliteSymbol(@"sqlite3_column_int");
    return f(stmt, iCol);
}

SQLITE_API const unsigned char *fbdfl_sqlite3_column_text(sqlite3_stmt *stmt, int iCol) {
    sqlite3_column_text_type f = (sqlite3_column_text_type)loadSqliteSymbol(@"sqlite3_column_text");
    return f(stmt, iCol);
}
