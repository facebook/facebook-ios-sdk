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

#import "FBInternalSettings.h"
#import "FBLogger.h"

static NSString *const g_frameworkPathTemplate = @"/System/Library/Frameworks/%@.framework/%@";
static NSString *const g_sqlitePath = @"/usr/lib/libsqlite3.dylib";

#pragma mark Library and Symbol Loading

struct FBDFLLoadSymbolContext {
    void *(*library)(void); // function to retrieve the library handle (it's a function instead of void * so it can be staticlly bound)
    const char *name;       // name of the symbol to retrieve
    void **address;         // [out] address of the symbol in the process address space
};

// Retrieves the handle for a library for framework. The paths for each are constructed
// differently so the loading function passed to dispatch_once() calls this.
static void *fbdfl_load_library_once(const char *path) {
    void *handle = dlopen(path, RTLD_LAZY);
    if (handle) {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorInformational formatString:@"Dynamically loaded library at %s", path];
    } else {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorInformational formatString:@"Failed to load library at %s", path];
    }
    return handle;
}

// Constructs the path for a system framework with the given name and returns the handle for dlsym
static void *fbdfl_load_framework_once(NSString *framework) {
    NSString *path = [NSString stringWithFormat:g_frameworkPathTemplate, framework, framework];
    return fbdfl_load_library_once([path fileSystemRepresentation]);
}

// Implements the callback for dispatch_once() that loads the handle for specified framework name
#define _fbdfl_load_framework_once_impl_(FRAMEWORK) \
    static void fbdfl_load_##FRAMEWORK##_once(void *context) { \
        *(void **)context = fbdfl_load_framework_once(@#FRAMEWORK); \
    }

// Implements the framework/library retrieval function for the given name.
// It calls the loading function once and caches the handle in a local static variable
#define _fbdfl_handle_get_impl_(LIBRARY) \
    static void *fbdfl_handle_get_##LIBRARY(void) { \
        static void *LIBRARY##_handle; \
        static dispatch_once_t LIBRARY##_once; \
        dispatch_once_f(&LIBRARY##_once, &LIBRARY##_handle, &fbdfl_load_##LIBRARY##_once); \
        return LIBRARY##_handle;\
    }

// Callback from dispatch_once() to load a specific symbol
static void fbdfl_load_symbol_once(void *context) {
    struct FBDFLLoadSymbolContext *ctx = context;
    *ctx->address = dlsym(ctx->library(), ctx->name);
}

// The boilerplate code for loading a symbol from a given library once and caching it in a static local
#define _fbdfl_symbol_get(LIBRARY, PREFIX, SYMBOL, TYPE, VARIABLE_NAME) \
    static TYPE VARIABLE_NAME; \
    static dispatch_once_t SYMBOL##_once; \
    static struct FBDFLLoadSymbolContext ctx = { .library = &fbdfl_handle_get_##LIBRARY, .name = PREFIX #SYMBOL, .address = (void **)&VARIABLE_NAME }; \
    dispatch_once_f(&SYMBOL##_once, &ctx, &fbdfl_load_symbol_once)

#define _fbdfl_symbol_get_c(LIBRARY, SYMBOL) _fbdfl_symbol_get(LIBRARY, "OBJC_CLASS_$_", SYMBOL, Class, c) // convenience symbol retrieval macro for getting an Objective-C class symbol and storing it in the local static c
#define _fbdfl_symbol_get_f(LIBRARY, SYMBOL) _fbdfl_symbol_get(LIBRARY, "", SYMBOL, SYMBOL##_type, f)      // convenience symbol retrieval macro for getting a function pointer and storing it in the local static f
#define _fbdfl_symbol_get_k(LIBRARY, SYMBOL, TYPE) _fbdfl_symbol_get(LIBRARY, "", SYMBOL, TYPE, k)         // convenience symbol retrieval macro for getting a pointer to a named variable and storing it in the local static k

// convenience macro for verifying a pointer to a named variable was successfully loaded and returns the value
#define _fbdfl_return_k(FRAMEWORK, SYMBOL) \
    NSCAssert(k != NULL, @"Failed to load constant %@ in the %@ framework", @#SYMBOL, @#FRAMEWORK); \
    return *k

// convenience macro for getting a pointer to a named NSString, verifying it loaded correctly, and returning it
#define _fbdfl_get_and_return_NSString(LIBRARY, SYMBOL) \
    _fbdfl_symbol_get_k(LIBRARY, SYMBOL, NSString **); \
    NSCAssert([*k isKindOfClass:[NSString class]], @"Loaded symbol %@ is not of type NSString *", @#SYMBOL); \
    _fbdfl_return_k(LIBRARY, SYMBOL)

#pragma mark Security Framework

_fbdfl_load_framework_once_impl_(Security)
_fbdfl_handle_get_impl_(Security)

#pragma mark Security Constants

@implementation FBDynamicFrameworkLoader

#define _fbdfl_Security_get_k(SYMBOL) _fbdfl_symbol_get_k(Security, SYMBOL, CFTypeRef *)

#define _fbdfl_Security_get_and_return_k(SYMBOL) \
    _fbdfl_Security_get_k(SYMBOL); \
    _fbdfl_return_k(Security, SYMBOL)

+ (SecRandomRef)loadkSecRandomDefault {
    _fbdfl_symbol_get_k(Security, kSecRandomDefault, SecRandomRef *);
    _fbdfl_return_k(Security, kSecRandomDefault);
}

+ (CFTypeRef)loadkSecAttrAccessible {
    _fbdfl_Security_get_and_return_k(kSecAttrAccessible);
}

+ (CFTypeRef)loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly {
    _fbdfl_Security_get_and_return_k(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly);
}

+ (CFTypeRef)loadkSecAttrAccount {
    _fbdfl_Security_get_and_return_k(kSecAttrAccount);
}

+ (CFTypeRef)loadkSecAttrService {
    _fbdfl_Security_get_and_return_k(kSecAttrService);
}

+ (CFTypeRef)loadkSecAttrGeneric {
    _fbdfl_Security_get_and_return_k(kSecAttrGeneric);
}

+ (CFTypeRef)loadkSecValueData {
    _fbdfl_Security_get_and_return_k(kSecValueData);
}

+ (CFTypeRef)loadkSecClassGenericPassword {
    _fbdfl_Security_get_and_return_k(kSecClassGenericPassword);
}

+ (CFTypeRef)loadkSecAttrAccessGroup {
    _fbdfl_Security_get_and_return_k(kSecAttrAccessGroup);
}

+ (CFTypeRef)loadkSecMatchLimitOne {
    _fbdfl_Security_get_and_return_k(kSecMatchLimitOne);
}

+ (CFTypeRef)loadkSecMatchLimit {
    _fbdfl_Security_get_and_return_k(kSecMatchLimit);
}

+ (CFTypeRef)loadkSecReturnData {
    _fbdfl_Security_get_and_return_k(kSecReturnData);
}

+ (CFTypeRef)loadkSecClass {
    _fbdfl_Security_get_and_return_k(kSecClass);
}

@end

#pragma mark Security APIs

#define _fbdfl_Security_get_f(SYMBOL) _fbdfl_symbol_get_f(Security, SYMBOL)

typedef int (*SecRandomCopyBytes_type)(SecRandomRef, size_t, uint8_t *);
typedef OSStatus (*SecItemUpdate_type)(CFDictionaryRef, CFDictionaryRef);
typedef OSStatus (*SecItemAdd_type)(CFDictionaryRef, CFTypeRef);
typedef OSStatus (*SecItemCopyMatching_type)(CFDictionaryRef, CFTypeRef);
typedef OSStatus (*SecItemDelete_type)(CFDictionaryRef);

int fbdfl_SecRandomCopyBytes(SecRandomRef rnd, size_t count, uint8_t *bytes) {
    _fbdfl_Security_get_f(SecRandomCopyBytes);
    return f(rnd, count, bytes);
}

OSStatus fbdfl_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
    _fbdfl_Security_get_f(SecItemUpdate);
    return f(query, attributesToUpdate);
}

OSStatus fbdfl_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result) {
    _fbdfl_Security_get_f(SecItemAdd);
    return f(attributes, result);
}

OSStatus fbdfl_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
    _fbdfl_Security_get_f(SecItemCopyMatching);
    return f(query, result);
}

OSStatus fbdfl_SecItemDelete(CFDictionaryRef query) {
    _fbdfl_Security_get_f(SecItemDelete);
    return f(query);
}

#pragma mark sqlite3 APIs

// sqlite3 is a dynamic library (not a framework) so its path is constructed differently
// than the way employed by the framework macros.
static void fbdfl_load_sqlite3_once(void *context) {
    *(void **)context = fbdfl_load_library_once([g_sqlitePath fileSystemRepresentation]);
}
_fbdfl_handle_get_impl_(sqlite3)

#define _fbdfl_sqlite3_get_f(SYMBOL) _fbdfl_symbol_get_f(sqlite3, SYMBOL)

typedef SQLITE_API const char *(*sqlite3_errmsg_type)(sqlite3 *);
typedef SQLITE_API int (*sqlite3_prepare_v2_type)(sqlite3 *, const char *, int, sqlite3_stmt **, const char **);
typedef SQLITE_API int (*sqlite3_reset_type)(sqlite3_stmt *);
typedef SQLITE_API int (*sqlite3_finalize_type)(sqlite3_stmt *);
typedef SQLITE_API int (*sqlite3_open_v2_type)(const char *, sqlite3 **, int, const char *);
typedef SQLITE_API int (*sqlite3_exec_type)(sqlite3 *, const char *, int (*)(void *, int, char **, char **), void *, char **);
typedef SQLITE_API int (*sqlite3_close_type)(sqlite3 *);
typedef SQLITE_API int (*sqlite3_bind_double_type)(sqlite3_stmt *, int, double);
typedef SQLITE_API int (*sqlite3_bind_int_type)(sqlite3_stmt *, int, int);
typedef SQLITE_API int (*sqlite3_bind_text_type)(sqlite3_stmt *, int, const char *, int, void(*)(void *));
typedef SQLITE_API int (*sqlite3_step_type)(sqlite3_stmt *);
typedef SQLITE_API double (*sqlite3_column_double_type)(sqlite3_stmt *, int);
typedef SQLITE_API int (*sqlite3_column_int_type)(sqlite3_stmt *, int);
typedef SQLITE_API const unsigned char *(*sqlite3_column_text_type)(sqlite3_stmt *, int);

SQLITE_API const char *fbdfl_sqlite3_errmsg(sqlite3 *db) {
    _fbdfl_sqlite3_get_f(sqlite3_errmsg);
    return f(db);
}

SQLITE_API int fbdfl_sqlite3_prepare_v2(sqlite3 *db, const char *zSql, int nByte, sqlite3_stmt **ppStmt, const char **pzTail) {
    _fbdfl_sqlite3_get_f(sqlite3_prepare_v2);
    return f(db, zSql, nByte, ppStmt, pzTail);
}

SQLITE_API int fbdfl_sqlite3_reset(sqlite3_stmt *pStmt) {
    _fbdfl_sqlite3_get_f(sqlite3_reset);
    return f(pStmt);
}

SQLITE_API int fbdfl_sqlite3_finalize(sqlite3_stmt *pStmt) {
    _fbdfl_sqlite3_get_f(sqlite3_finalize);
    return f(pStmt);
}

SQLITE_API int fbdfl_sqlite3_open_v2(const char *filename, sqlite3 **ppDb, int flags, const char *zVfs) {
    _fbdfl_sqlite3_get_f(sqlite3_open_v2);
    return f(filename, ppDb, flags, zVfs);
}

SQLITE_API int fbdfl_sqlite3_exec(sqlite3 *db, const char *sql, int (*callback)(void *, int, char **, char **), void *arg, char **errmsg) {
    _fbdfl_sqlite3_get_f(sqlite3_exec);
    return f(db, sql, callback, arg, errmsg);
}

SQLITE_API int fbdfl_sqlite3_close(sqlite3 *db) {
    _fbdfl_sqlite3_get_f(sqlite3_close);
    return f(db);
}

SQLITE_API int fbdfl_sqlite3_bind_double(sqlite3_stmt *stmt, int index , double value) {
    _fbdfl_sqlite3_get_f(sqlite3_bind_double);
    return f(stmt, index, value);
}

SQLITE_API int fbdfl_sqlite3_bind_int(sqlite3_stmt *stmt, int index, int value) {
    _fbdfl_sqlite3_get_f(sqlite3_bind_int);
    return f(stmt, index, value);
}

SQLITE_API int fbdfl_sqlite3_bind_text(sqlite3_stmt *stmt, int index, const char *value, int n, void(*callback)(void *)) {
    _fbdfl_sqlite3_get_f(sqlite3_bind_text);
    return f(stmt, index, value, n, callback);
}

SQLITE_API int fbdfl_sqlite3_step(sqlite3_stmt *stmt) {
    _fbdfl_sqlite3_get_f(sqlite3_step);
    return f(stmt);
}

SQLITE_API double fbdfl_sqlite3_column_double(sqlite3_stmt *stmt, int iCol) {
    _fbdfl_sqlite3_get_f(sqlite3_column_double);
    return f(stmt, iCol);
}

SQLITE_API int fbdfl_sqlite3_column_int(sqlite3_stmt *stmt, int iCol) {
    _fbdfl_sqlite3_get_f(sqlite3_column_int);
    return f(stmt, iCol);
}

SQLITE_API const unsigned char *fbdfl_sqlite3_column_text(sqlite3_stmt *stmt, int iCol) {
    _fbdfl_sqlite3_get_f(sqlite3_column_text);
    return f(stmt, iCol);
}

#pragma mark Social Constants

_fbdfl_load_framework_once_impl_(Social)
_fbdfl_handle_get_impl_(Social)

#define _fbdfl_Social_get_and_return_constant(SYMBOL) _fbdfl_get_and_return_NSString(Social, SYMBOL)

NSString *fbdfl_SLServiceTypeFacebook(void) {
    _fbdfl_Social_get_and_return_constant(SLServiceTypeFacebook);
}

#pragma mark Social Classes

#define _fbdfl_Social_get_c(SYMBOL) _fbdfl_symbol_get_c(Social, SYMBOL)

Class fbdfl_SLComposeViewControllerClass(void) {
    _fbdfl_Social_get_c(SLComposeViewController);
    return c;
}

#pragma mark QuartzCore Classes

_fbdfl_load_framework_once_impl_(QuartzCore)
_fbdfl_handle_get_impl_(QuartzCore)

#define _fbdfl_QuartzCore_get_c(SYMBOL) _fbdfl_symbol_get_c(QuartzCore, SYMBOL);

Class fbdfl_CATransactionClass(void) {
    _fbdfl_QuartzCore_get_c(CATransaction);
    return c;
}

#pragma mark QuartzCore APIs

#define _fbdfl_QuartzCore_get_f(SYMBOL) _fbdfl_symbol_get_f(QuartzCore, SYMBOL)

typedef CATransform3D (*CATransform3DMakeScale_type)(CGFloat, CGFloat, CGFloat);
typedef CATransform3D (*CATransform3DMakeTranslation_type)(CGFloat, CGFloat, CGFloat);
typedef CATransform3D (*CATransform3DConcat_type)(CATransform3D, CATransform3D);

const CATransform3D fbdfl_CATransform3DIdentity = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1};

CATransform3D fbdfl_CATransform3DMakeScale(CGFloat sx, CGFloat sy, CGFloat sz) {
    _fbdfl_QuartzCore_get_f(CATransform3DMakeScale);
    return f(sx, sy, sz);
}

CATransform3D fbdfl_CATransform3DMakeTranslation(CGFloat tx, CGFloat ty, CGFloat tz) {
    _fbdfl_QuartzCore_get_f(CATransform3DMakeTranslation);
    return f(tx, ty, tz);
}

CATransform3D fbdfl_CATransform3DConcat(CATransform3D a, CATransform3D b) {
    _fbdfl_QuartzCore_get_f(CATransform3DConcat);
    return f(a, b);
}

#pragma mark AudioToolbox APIs

_fbdfl_load_framework_once_impl_(AudioToolbox)
_fbdfl_handle_get_impl_(AudioToolbox)

#define _fbdfl_AudioToolbox_get_f(SYMBOL) _fbdfl_symbol_get_f(AudioToolbox, SYMBOL)

typedef OSStatus (*AudioServicesCreateSystemSoundID_type)(CFURLRef, SystemSoundID *);
typedef OSStatus (*AudioServicesDisposeSystemSoundID_type)(SystemSoundID);
typedef void (*AudioServicesPlaySystemSound_type)(SystemSoundID);

OSStatus fbdfl_AudioServicesCreateSystemSoundID(CFURLRef inFileURL, SystemSoundID *outSystemSoundID) {
    _fbdfl_AudioToolbox_get_f(AudioServicesCreateSystemSoundID);
    return f(inFileURL, outSystemSoundID);
}

OSStatus fbdfl_AudioServicesDisposeSystemSoundID(SystemSoundID inSystemSoundID) {
    _fbdfl_AudioToolbox_get_f(AudioServicesDisposeSystemSoundID);
    return f(inSystemSoundID);
}

void fbdfl_AudioServicesPlaySystemSound(SystemSoundID inSystemSoundID) {
    _fbdfl_AudioToolbox_get_f(AudioServicesPlaySystemSound);
    return f(inSystemSoundID);
}

#pragma mark Ad Support Classes

_fbdfl_load_framework_once_impl_(AdSupport)
_fbdfl_handle_get_impl_(AdSupport)

#define _fbdfl_AdSupport_get_c(SYMBOL) _fbdfl_symbol_get_c(AdSupport, SYMBOL);

Class fbdfl_ASIdentifierManagerClass(void) {
    _fbdfl_AdSupport_get_c(ASIdentifierManager);
    return c;
}

#pragma mark - Safari Services
_fbdfl_load_framework_once_impl_(SafariServices)
_fbdfl_handle_get_impl_(SafariServices)

#define _fbdfl_SafariServices_get_c(SYMBOL) _fbdfl_symbol_get_c(SafariServices, SYMBOL);

Class fbdfl_SFSafariViewControllerClass(void)
{
    _fbdfl_SafariServices_get_c(SFSafariViewController);
    return c;
}

#pragma mark Accounts Constants

_fbdfl_load_framework_once_impl_(Accounts)
_fbdfl_handle_get_impl_(Accounts)

#define _fbdfl_Accounts_get_and_return_NSString(SYMBOL) _fbdfl_get_and_return_NSString(Accounts, SYMBOL)

NSString *fbdfl_ACFacebookAppIdKey(void) {
    _fbdfl_Accounts_get_and_return_NSString(ACFacebookAppIdKey);
}

NSString *fbdfl_ACFacebookAudienceEveryone(void) {
    _fbdfl_Accounts_get_and_return_NSString(ACFacebookAudienceEveryone);
}

NSString *fbdfl_ACFacebookAudienceFriends(void) {
    _fbdfl_Accounts_get_and_return_NSString(ACFacebookAudienceFriends);
}

NSString *fbdfl_ACFacebookAudienceKey(void) {
    _fbdfl_Accounts_get_and_return_NSString(ACFacebookAudienceKey);
}

NSString *fbdfl_ACFacebookAudienceOnlyMe(void) {
    _fbdfl_Accounts_get_and_return_NSString(ACFacebookAudienceOnlyMe);
}

NSString *fbdfl_ACFacebookPermissionsKey(void) {
    _fbdfl_Accounts_get_and_return_NSString(ACFacebookPermissionsKey);
}

#pragma mark Accounts Classes

#define _fbdfl_Accounts_get_c(SYMBOL) _fbdfl_symbol_get_c(Accounts, SYMBOL);

Class fbdfl_ACAccountStoreClass(void) {
    _fbdfl_Accounts_get_c(ACAccountStore);
    return c;
}

#pragma mark StoreKit Classes

_fbdfl_load_framework_once_impl_(StoreKit)
_fbdfl_handle_get_impl_(StoreKit)

#define _fbdfl_StoreKit_get_c(SYMBOL) _fbdfl_symbol_get_c(StoreKit, SYMBOL);

Class fbdfl_SKPaymentQueueClass(void) {
    _fbdfl_StoreKit_get_c(SKPaymentQueue);
    return c;
}

Class fbdfl_SKProductsRequestClass(void) {
    _fbdfl_StoreKit_get_c(SKProductsRequest);
    return c;
}
