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

#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Security/Security.h>
#import <StoreKit/StoreKit.h>

#import "FBSDKMacros.h"

/*!
 @class FBDynamicFrameworkLoader

 @abstract
 This class provides a way to load constants and methods from Apple Frameworks in a dynamic
 fashion.  It allows the SDK to be just dragged into a project without having to specify additional
 frameworks to link against.  It is an internal class and not to be used by 3rd party developers.

 As new types are needed, they should be added and strongly typed.
 */
@interface FBDynamicFrameworkLoader : NSObject

#pragma mark Security Constants

/*!
 @abstract
 Load the kSecRandomDefault value from the Security Framework

 @return The kSecRandomDefault value or nil.
 */
+ (SecRandomRef)loadkSecRandomDefault;

/*!
 @abstract
 Load the kSecAttrAccessible value from the Security Framework

 @return The kSecAttrAccessible value or nil.
 */
+ (CFTypeRef)loadkSecAttrAccessible;

/*!
 @abstract
 Load the kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly value from the Security Framework

 @return The kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly value or nil.
 */
+ (CFTypeRef)loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;

/*!
 @abstract
 Load the kSecAttrAccount value from the Security Framework

 @return The kSecAttrAccount value or nil.
 */
+ (CFTypeRef)loadkSecAttrAccount;

/*!
 @abstract
 Load the kSecAttrService value from the Security Framework

 @return The kSecAttrService value or nil.
 */
+ (CFTypeRef)loadkSecAttrService;

/*!
 @abstract
 Load the kSecAttrGeneric value from the Security Framework

 @return The kSecAttrGeneric value or nil.
 */
+ (CFTypeRef)loadkSecAttrGeneric;

/*!
 @abstract
 Load the kSecValueData value from the Security Framework

 @return The kSecValueData value or nil.
 */
+ (CFTypeRef)loadkSecValueData;

/*!
 @abstract
 Load the kSecClassGenericPassword value from the Security Framework

 @return The kSecClassGenericPassword value or nil.
 */
+ (CFTypeRef)loadkSecClassGenericPassword;

/*!
 @abstract
 Load the kSecAttrAccessGroup value from the Security Framework

 @return The kSecAttrAccessGroup value or nil.
 */
+ (CFTypeRef)loadkSecAttrAccessGroup;

/*!
 @abstract
 Load the kSecMatchLimitOne value from the Security Framework

 @return The kSecMatchLimitOne value or nil.
 */
+ (CFTypeRef)loadkSecMatchLimitOne;

/*!
 @abstract
 Load the kSecMatchLimit value from the Security Framework

 @return The kSecMatchLimit value or nil.
 */
+ (CFTypeRef)loadkSecMatchLimit;

/*!
 @abstract
 Load the kSecReturnData value from the Security Framework

 @return The kSecReturnData value or nil.
 */
+ (CFTypeRef)loadkSecReturnData;

/*!
 @abstract
 Load the kSecClass value from the Security Framework

 @return The kSecClass value or nil.
 */
+ (CFTypeRef)loadkSecClass;

@end

#pragma mark Security APIs

// These are local wrappers around the corresponding methods in Security/SecRandom.h
int fbdfl_SecRandomCopyBytes(SecRandomRef rnd, size_t count, uint8_t *bytes);

// These are local wrappers around Keychain API
OSStatus fbdfl_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate);
OSStatus fbdfl_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result);
OSStatus fbdfl_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result);
OSStatus fbdfl_SecItemDelete(CFDictionaryRef query);

#pragma mark sqlite3 APIs

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

#pragma mark Social Constants

NSString *fbdfl_SLServiceTypeFacebook(void);

#pragma mark Social Classes

Class fbdfl_SLComposeViewControllerClass(void);

#pragma mark QuartzCore Classes

Class fbdfl_CATransactionClass(void);

#pragma mark QuartzCore APIs

// These are local wrappers around the corresponding transform methods from QuartzCore.framework/CATransform3D.h
CATransform3D fbdfl_CATransform3DMakeScale (CGFloat sx, CGFloat sy, CGFloat sz);
CATransform3D fbdfl_CATransform3DMakeTranslation (CGFloat tx, CGFloat ty, CGFloat tz);
CATransform3D fbdfl_CATransform3DConcat (CATransform3D a, CATransform3D b);

FBSDK_EXTERN const CATransform3D fbdfl_CATransform3DIdentity;

#pragma mark AudioToolbox APIs

// These are local wrappers around the corresponding methods in AudioToolbox/AudioToolbox.h
OSStatus fbdfl_AudioServicesCreateSystemSoundID(CFURLRef inFileURL, SystemSoundID *outSystemSoundID);
OSStatus fbdfl_AudioServicesDisposeSystemSoundID(SystemSoundID inSystemSoundID);
void fbdfl_AudioServicesPlaySystemSound(SystemSoundID inSystemSoundID);

#pragma mark AdSupport Classes

Class fbdfl_ASIdentifierManagerClass(void);

#pragma mark - SafariServices Classes

FBSDK_EXTERN Class fbdfl_SFSafariViewControllerClass(void);

#pragma mark Accounts Constants

NSString *fbdfl_ACFacebookAppIdKey(void);
NSString *fbdfl_ACFacebookAudienceEveryone(void);
NSString *fbdfl_ACFacebookAudienceFriends(void);
NSString *fbdfl_ACFacebookAudienceKey(void);
NSString *fbdfl_ACFacebookAudienceOnlyMe(void);
NSString *fbdfl_ACFacebookPermissionsKey(void);

#pragma mark Accounts Classes

Class fbdfl_ACAccountStoreClass(void);

#pragma mark StoreKit classes

Class fbdfl_SKPaymentQueueClass(void);
Class fbdfl_SKProductsRequestClass(void);
