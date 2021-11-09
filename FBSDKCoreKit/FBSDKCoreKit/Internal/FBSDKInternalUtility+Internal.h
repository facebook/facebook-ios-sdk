/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKInfoDictionaryProviding;

/**
 Describes the callback for appLinkFromURLInBackground.
 @param object the FBSDKAppLink representing the deferred App Link
 @param stop the error during the request, if any

 */
typedef id _Nullable (^ FBSDKInvalidObjectHandler)(id object, BOOL *stop)
NS_SWIFT_NAME(InvalidObjectHandler);

@interface FBSDKInternalUtility (Internal)
#if !TARGET_OS_TV
<FBSDKWindowFinding>
#endif

/**
  Constructs the scheme for apps that come to the current app through the bridge.
 */
@property (nonatomic, readonly, copy) NSString *appURLScheme;

/**
 Gets the milliseconds since the Unix Epoch.

 Changes in the system clock will affect this value.
 @return The number of milliseconds since the Unix Epoch.
 */
@property (nonatomic, readonly, assign) uint64_t currentTimeInMilliseconds;

/**
 The version of the operating system on which the process is executing.
 */
@property (nonatomic, readonly, assign) NSOperatingSystemVersion operatingSystemVersion;

/*
 Checks if the app is Unity.
 */
@property (nonatomic, readonly, assign) BOOL isUnity;

- (void)configureWithInfoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
                              loggerFactory:(id<__FBSDKLoggerCreating>)loggerFactory;

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
                                queryParameters:(NSDictionary<NSString *, id> *)queryParameters
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
  add data processing options to the dictionary.
 */
- (void)extendDictionaryWithDataProcessingOptions:(NSMutableDictionary<NSString *, id> *)parameters;

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

#define FB_BASE_URL @"facebook.com"

@end

NS_ASSUME_NONNULL_END
