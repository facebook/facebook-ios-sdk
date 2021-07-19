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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "FBSDKInternalUtility.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKInfoDictionaryProviding;

/**
 Describes the callback for appLinkFromURLInBackground.
 @param object the FBSDKAppLink representing the deferred App Link
 @param stop the error during the request, if any

 */
typedef id _Nullable (^FBSDKInvalidObjectHandler)(id object, BOOL *stop)
NS_SWIFT_NAME(InvalidObjectHandler);

@interface FBSDKInternalUtility (Internal)

+ (void)configureWithInfoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider;

/**
  Constructs the scheme for apps that come to the current app through the bridge.
 */
@property (nonatomic, copy, readonly) NSString *appURLScheme;

/**
 Gets the milliseconds since the Unix Epoch.

 Changes in the system clock will affect this value.
 @return The number of milliseconds since the Unix Epoch.
 */
@property (nonatomic, assign, readonly) uint64_t currentTimeInMilliseconds;

/**
 The version of the operating system on which the process is executing.
 */
@property (nonatomic, assign, readonly) NSOperatingSystemVersion operatingSystemVersion;

/*
 Checks if the app is Unity.
 */
@property (nonatomic, assign, readonly) BOOL isUnity;

/**
  Constructs a Facebook URL.
 @param hostPrefix The prefix for the host, such as 'm', 'graph', etc.
 @param path The path for the URL.  This may or may not include a version.
 @param queryParameters The query parameters for the URL.  This will be converted into a query string.
 @param defaultVersion A version to add to the URL if none is found in the path.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return The Facebook URL.
 */
- (NSURL *)facebookURLWithHostPrefix:(NSString *)hostPrefix
                                path:(NSString *)path
                     queryParameters:(NSDictionary<NSString *, NSString *> *)queryParameters
                      defaultVersion:(NSString *)defaultVersion
                               error:(NSError *__autoreleasing *)errorRef;

/**
  Constructs a Facebook URL that doesn't need to specify an API version.
 @param hostPrefix The prefix for the host, such as 'm', 'graph', etc.
 @param path The path for the URL.  This may or may not include a version.
 @param queryParameters The query parameters for the URL.  This will be converted into a query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return The Facebook URL.
 */
- (NSURL *)unversionedFacebookURLWithHostPrefix:(NSString *)hostPrefix
                                           path:(NSString *)path
                                queryParameters:(NSDictionary *)queryParameters
                                          error:(NSError *__autoreleasing *)errorRef;

/**
  Tests whether the supplied bundle identifier references a Facebook app.
 @param bundleIdentifier The bundle identifier to test.
 @return YES if the bundle identifier refers to a Facebook app, otherwise NO.
 */
- (BOOL)isFacebookBundleIdentifier:(NSString *)bundleIdentifier;

/**
  Tests whether the supplied bundle identifier references the Safari app.
 @param bundleIdentifier The bundle identifier to test.
 @return YES if the bundle identifier refers to the Safari app, otherwise NO.
 */
- (BOOL)isSafariBundleIdentifier:(NSString *)bundleIdentifier;

/**
 *  Deletes all the cookies in the NSHTTPCookieStorage for Facebook web dialogs
 */
- (void)deleteFacebookCookies;


/**
  validates that Facebook reserved URL schemes are not registered, throws an NSException if they are.
 */
- (void)validateFacebookReservedURLSchemes;

/**
 returns the current key window
 */
- (nullable UIWindow *)findWindow;

#if !TARGET_OS_TV
/**
  returns interface orientation for the key window.
 */
- (UIInterfaceOrientation)statusBarOrientation;
#endif

/**
  Converts NSData to a hexadecimal UTF8 String.
 */
- (nullable NSString *)hexadecimalStringFromData:(NSData *)data;

/*
  Checks if the permission is a publish permission.
 */
- (BOOL)isPublishPermission:(NSString *)permission;

#define FBSDKConditionalLog(condition, loggingBehavior, desc, ...) \
{ \
  if (!(condition)) { \
    NSString *msg = [NSString stringWithFormat:(desc), ##__VA_ARGS__]; \
    [FBSDKLogger singleShotLogEntry:loggingBehavior logEntry:msg]; \
  } \
}

#define FB_BASE_URL @"facebook.com"

@end

NS_ASSUME_NONNULL_END
