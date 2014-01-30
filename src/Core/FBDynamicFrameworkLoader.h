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

#import <sqlite3.h>

#import <Foundation/Foundation.h>
#import <Security/Security.h>

/*!
 @class FBDynamicFrameworkLoader

 @abstract
 This class provides a way to load constants and methods from Apple Frameworks in a dynamic
 fashion.  It allows the SDK to be just dragged into a project without having to specify additional
 frameworks to link against.  It is an internal class and not to be used by 3rd party developers.

 This class is a generic class for loading Classes, NSStrings, and SecRandomRef.
 As new types are needed, they should be added and strongly typed.
 */
@interface FBDynamicFrameworkLoader : NSObject

/*!
 @abstract
 Loads a Class and returns the Class object.  This can then be used to create an instance of the class.

 @param className  An NSString of the name of the class

 @param frameworkName The framework in which the class appears

 @return The Class object or nil if it fails to load.
 */
+ (Class)loadClass:(NSString *)className withFramework:(NSString *)frameworkName;

/*!
 @abstract
 Loads a string constant and return the string.

 @param constantName  An NSString of the name of the constant

 @param frameworkName The framework in which the constant appears

 @return The string or nil if it fails to load.
 */
+ (NSString *)loadStringConstant:(NSString *)constantName withFramework:(NSString *)frameworkName;

/*!
 @abstract
 Load the kSecRandomDefault value from the Security Framework

 @return The kSecRandomDefault value or nil.
 */
+ (SecRandomRef)loadkSecRandomDefault;

/*!
 @abstract
 Returns the path template to the Frameworks.
 We will try and load the template passing in the framework twice
 "/System/Library/Frameworks/%@.framework/%@" is the default value.

 @return The path template for loading Frameworks
 */
+ (NSString *)frameworkPathTemplate;

/*!
 @abstract
 Sets the path template of where to load Frameworks from
 This will be loaded with [NSString stringWithFormat:pathTemplate, framework, framework]

 @param pathTemplate An NSString of the pathTemplate

 @return void
 */
+ (void)setFrameworkPathTemplate:(NSString *)pathTemplate;

/*!
 @abstract
 Returns the path to the Sqlite library

 @return The path we will attempt to load the Sqlite library from
 */
+ (NSString *)sqlitePath;

/*!
 @abstract
 Sets the path of where to load the Sqlite library from

 @param path An NSString of the path

 @return void
 */
+ (void)setSqlitePath:(NSString *)path;

@end

// Security c-style APIs
// These are local wrappers around the corresponding methods in Security/SecRandom.h
int fbdfl_SecRandomCopyBytes(SecRandomRef rnd, size_t count, uint8_t *bytes);

// SQLITE3 c-style APIs
// These are local wrappers around the corresponding sqlite3 method from /usr/include/sqlite3.h
SQLITE_API const char *fbdfl_sqlite3_errmsg(sqlite3 *db);
SQLITE_API int fbdfl_sqlite3_prepare_v2(sqlite3 *db, const char *zSql, int nByte, sqlite3_stmt **ppStmt, const char **pzTail);
SQLITE_API int fbdfl_sqlite3_reset(sqlite3_stmt *pStmt);
SQLITE_API int fbdfl_sqlite3_finalize(sqlite3_stmt *pStmt);
SQLITE_API int fbdfl_sqlite3_open_v2(const char *filename, sqlite3 **ppDb, int flags, const char *zVfs);
SQLITE_API int fbdfl_sqlite3_exec(sqlite3 *db, const char *sql, int (*callback)(void *, int, char **, char **), void *arg, char **errmsg);
SQLITE_API int fbdfl_sqlite3_close(sqlite3 *db);
SQLITE_API int fbdfl_sqlite3_bind_double(sqlite3_stmt *stmt, int index, double value);
SQLITE_API int fbdfl_sqlite3_bind_int(sqlite3_stmt *stmt, int index, int value);
SQLITE_API int fbdfl_sqlite3_bind_text(sqlite3_stmt *stmt, int index, const char *value, int n, void(*callback)(void *));
SQLITE_API int fbdfl_sqlite3_step(sqlite3_stmt *stmt);
SQLITE_API double fbdfl_sqlite3_column_double(sqlite3_stmt *stmt, int iCol);
SQLITE_API int fbdfl_sqlite3_column_int(sqlite3_stmt *stmt, int iCol);
SQLITE_API const unsigned char *fbdfl_sqlite3_column_text(sqlite3_stmt *stmt, int iCol);


