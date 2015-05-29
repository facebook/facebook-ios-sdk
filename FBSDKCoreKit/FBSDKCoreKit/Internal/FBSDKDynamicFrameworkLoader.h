// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <sqlite3.h>

#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import <FBSDKCoreKit/FBSDKMacros.h>

/*!
 @class FBSDKDynamicFrameworkLoader

 @abstract
 This class provides a way to load constants and methods from Apple Frameworks in a dynamic
 fashion.  It allows the SDK to be just dragged into a project without having to specify additional
 frameworks to link against.  It is an internal class and not to be used by 3rd party developers.

 As new types are needed, they should be added and strongly typed.
 */
@interface FBSDKDynamicFrameworkLoader : NSObject

#pragma mark - Security Constants

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

#pragma mark - Security APIs

// These are local wrappers around the corresponding methods in Security/SecRandom.h
FBSDK_EXTERN int fbsdkdfl_SecRandomCopyBytes(SecRandomRef rnd, size_t count, uint8_t *bytes);

// These are local wrappers around Keychain API
FBSDK_EXTERN OSStatus fbsdkdfl_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate);
FBSDK_EXTERN OSStatus fbsdkdfl_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result);
FBSDK_EXTERN OSStatus fbsdkdfl_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result);
FBSDK_EXTERN OSStatus fbsdkdfl_SecItemDelete(CFDictionaryRef query);

#pragma mark - sqlite3 APIs

// These are local wrappers around the corresponding sqlite3 method from /usr/include/sqlite3.h
FBSDK_EXTERN SQLITE_API const char *fbsdkdfl_sqlite3_errmsg(sqlite3 *db);
FBSDK_EXTERN SQLITE_API int fbsdkdfl_sqlite3_prepare_v2(sqlite3 *db, const char *zSql, int nByte, sqlite3_stmt **ppStmt, const char **pzTail);
FBSDK_EXTERN SQLITE_API int fbsdkdfl_sqlite3_reset(sqlite3_stmt *pStmt);
FBSDK_EXTERN SQLITE_API int fbsdkdfl_sqlite3_finalize(sqlite3_stmt *pStmt);
FBSDK_EXTERN SQLITE_API int fbsdkdfl_sqlite3_open_v2(const char *filename, sqlite3 **ppDb, int flags, const char *zVfs);
FBSDK_EXTERN SQLITE_API int fbsdkdfl_sqlite3_exec(sqlite3 *db, const char *sql, int (*callback)(void *, int, char **, char **), void *arg, char **errmsg);
FBSDK_EXTERN SQLITE_API int fbsdkdfl_sqlite3_close(sqlite3 *db);
FBSDK_EXTERN SQLITE_API int fbsdkdfl_sqlite3_bind_double(sqlite3_stmt *stmt, int index, double value);
FBSDK_EXTERN SQLITE_API int fbsdkdfl_sqlite3_bind_int(sqlite3_stmt *stmt, int index, int value);
FBSDK_EXTERN SQLITE_API int fbsdkdfl_sqlite3_bind_text(sqlite3_stmt *stmt, int index, const char *value, int n, void(*callback)(void *));
FBSDK_EXTERN SQLITE_API int fbsdkdfl_sqlite3_step(sqlite3_stmt *stmt);
FBSDK_EXTERN SQLITE_API double fbsdkdfl_sqlite3_column_double(sqlite3_stmt *stmt, int iCol);
FBSDK_EXTERN SQLITE_API int fbsdkdfl_sqlite3_column_int(sqlite3_stmt *stmt, int iCol);
FBSDK_EXTERN SQLITE_API const unsigned char *fbsdkdfl_sqlite3_column_text(sqlite3_stmt *stmt, int iCol);

#pragma mark - Social Constants

FBSDK_EXTERN NSString *fbsdkdfl_SLServiceTypeFacebook(void);

#pragma mark - Social Classes

FBSDK_EXTERN Class fbsdkdfl_SLComposeViewControllerClass(void);

#pragma mark - QuartzCore Classes

FBSDK_EXTERN Class fbsdkdfl_CATransactionClass(void);

#pragma mark - QuartzCore APIs

// These are local wrappers around the corresponding transform methods from QuartzCore.framework/CATransform3D.h
FBSDK_EXTERN CATransform3D fbsdkdfl_CATransform3DMakeScale (CGFloat sx, CGFloat sy, CGFloat sz);
FBSDK_EXTERN CATransform3D fbsdkdfl_CATransform3DMakeTranslation (CGFloat tx, CGFloat ty, CGFloat tz);
FBSDK_EXTERN CATransform3D fbsdkdfl_CATransform3DConcat (CATransform3D a, CATransform3D b);

FBSDK_EXTERN const CATransform3D fbsdkdfl_CATransform3DIdentity;

#pragma mark - AudioToolbox APIs

// These are local wrappers around the corresponding methods in AudioToolbox/AudioToolbox.h
FBSDK_EXTERN OSStatus fbsdkdfl_AudioServicesCreateSystemSoundID(CFURLRef inFileURL, SystemSoundID *outSystemSoundID);
FBSDK_EXTERN OSStatus fbsdkdfl_AudioServicesDisposeSystemSoundID(SystemSoundID inSystemSoundID);
FBSDK_EXTERN void fbsdkdfl_AudioServicesPlaySystemSound(SystemSoundID inSystemSoundID);

#pragma mark - AdSupport Classes

FBSDK_EXTERN Class fbsdkdfl_ASIdentifierManagerClass(void);

#pragma mark - Accounts Constants

FBSDK_EXTERN NSString *fbsdkdfl_ACFacebookAppIdKey(void);
FBSDK_EXTERN NSString *fbsdkdfl_ACFacebookAudienceEveryone(void);
FBSDK_EXTERN NSString *fbsdkdfl_ACFacebookAudienceFriends(void);
FBSDK_EXTERN NSString *fbsdkdfl_ACFacebookAudienceKey(void);
FBSDK_EXTERN NSString *fbsdkdfl_ACFacebookAudienceOnlyMe(void);
FBSDK_EXTERN NSString *fbsdkdfl_ACFacebookPermissionsKey(void);

#pragma mark - Accounts Classes

FBSDK_EXTERN Class fbsdkdfl_ACAccountStoreClass(void);

#pragma mark - StoreKit classes

FBSDK_EXTERN Class fbsdkdfl_SKPaymentQueueClass(void);
FBSDK_EXTERN Class fbsdkdfl_SKProductsRequestClass(void);

#pragma mark - AssetsLibrary Classes

FBSDK_EXTERN Class fbsdkdfl_ALAssetsLibraryClass(void);

#pragma mark - CoreTelephony Classes

FBSDK_EXTERN Class fbsdkdfl_CTTelephonyNetworkInfoClass(void);
