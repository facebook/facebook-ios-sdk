/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKAppAvailabilityChecker.h>
#import <FBSDKCoreKit/FBSDKAppURLSchemeProviding.h>
#import <FBSDKCoreKit/FBSDKInternalUtilityProtocol.h>

#if !TARGET_OS_TV
 #import <FBSDKCoreKit/FBSDKURLHosting.h>
#endif

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const FBSDK_CANOPENURL_FACEBOOK
  DEPRECATED_MSG_ATTRIBUTE("`FBSDK_CANOPENURL_FACEBOOK` is deprecated and will be removed in the next major release; please use `URLScheme.facebookAPI` instead");
FOUNDATION_EXPORT NSString *const FBSDK_CANOPENURL_FBAPI
  DEPRECATED_MSG_ATTRIBUTE("`FBSDK_CANOPENURL_FBAPI` is deprecated and will be removed in the next major release; please use `URLScheme.facebookAPI` instead");
FOUNDATION_EXPORT NSString *const FBSDK_CANOPENURL_MESSENGER
  DEPRECATED_MSG_ATTRIBUTE("`FBSDK_CANOPENURL_MESSENGER` is deprecated and will be removed in the next major release; please use `URLScheme.messengerApp` instead");
FOUNDATION_EXPORT NSString *const FBSDK_CANOPENURL_MSQRD_PLAYER
  DEPRECATED_MSG_ATTRIBUTE("`FBSDK_CANOPENURL_MSQRD_PLAYER` is deprecated and will be removed in the next major release");
FOUNDATION_EXPORT NSString *const FBSDK_CANOPENURL_SHARE_EXTENSION
  DEPRECATED_MSG_ATTRIBUTE("`FBSDK_CANOPENURL_SHARE_EXTENSION` is deprecated and will be removed in the next major release; please use `URLScheme.facebookAPI`");

NS_SWIFT_NAME(InternalUtility)
@interface FBSDKInternalUtility : NSObject
#if !TARGET_OS_TV
  <FBSDKAppAvailabilityChecker, FBSDKAppURLSchemeProviding, FBSDKInternalUtility, FBSDKURLHosting>
#else
  <FBSDKAppAvailabilityChecker, FBSDKAppURLSchemeProviding, FBSDKInternalUtility>
#endif

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (class, nonnull, readonly) FBSDKInternalUtility *sharedUtility;

/**
 Returns bundle for returning localized strings

 We assume a convention of a bundle named FBSDKStrings.bundle, otherwise we
 return the main bundle.
 */
@property (nonatomic, readonly, strong) NSBundle *bundleForStrings;

/**
  Constructs an URL for the current app.
 @param host The host for the URL.
 @param path The path for the URL.
 @param queryParameters The query parameters for the URL.  This will be converted into a query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return The app URL.
 */
- (NSURL *)appURLWithHost:(NSString *)host
                     path:(NSString *)path
          queryParameters:(NSDictionary<NSString *, NSString *> *)queryParameters
                    error:(NSError *__autoreleasing *)errorRef;

/**
  Parses an FB url's query params (and potentially fragment) into a dictionary.
 @param url The FB url.
 @return A dictionary with the key/value pairs.
 */
- (NSDictionary<NSString *, id> *)parametersFromFBURL:(NSURL *)url;

/**
  Constructs a Facebook URL.
 @param hostPrefix The prefix for the host, such as 'm', 'graph', etc.
 @param path The path for the URL.  This may or may not include a version.
 @param queryParameters The query parameters for the URL.  This will be converted into a query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return The Facebook URL.
 */
- (NSURL *)facebookURLWithHostPrefix:(NSString *)hostPrefix
                                path:(NSString *)path
                     queryParameters:(NSDictionary<NSString *, NSString *> *)queryParameters
                               error:(NSError *__autoreleasing *)errorRef;

/**
  Tests whether the supplied URL is a valid URL for opening in the browser.
 @param URL The URL to test.
 @return YES if the URL refers to an http or https resource, otherwise NO.
 */
- (BOOL)isBrowserURL:(NSURL *)URL;

/**
  Checks equality between 2 objects.

 Checks for pointer equality, nils, isEqual:.
 @param object The first object to compare.
 @param other The second object to compare.
 @return YES if the objects are equal, otherwise NO.
 */
- (BOOL)object:(id)object isEqualToObject:(id)other;

/**
  Extracts permissions from a response fetched from me/permissions
 @param responseObject the response
 @param grantedPermissions the set to add granted permissions to
 @param declinedPermissions the set to add declined permissions to.
 */
- (void)extractPermissionsFromResponse:(NSDictionary<NSString *, id> *)responseObject
                    grantedPermissions:(NSMutableSet<NSString *> *)grantedPermissions
                   declinedPermissions:(NSMutableSet<NSString *> *)declinedPermissions
                    expiredPermissions:(NSMutableSet<NSString *> *)expiredPermissions;

/**
  validates that the app ID is non-nil, throws an NSException if nil.
 */
- (void)validateAppID;

/**
 Validates that the client access token is non-nil, otherwise - throws an NSException otherwise.
 Returns the composed client access token.
 */
- (NSString *)validateRequiredClientAccessToken;

/**
  Attempts to find the first UIViewController in the view's responder chain. Returns nil if not found.
 */
- (nullable UIViewController *)viewControllerForView:(UIView *)view;

/**
  returns true if the url scheme is registered in the CFBundleURLTypes
 */
- (BOOL)isRegisteredURLScheme:(NSString *)urlScheme;

/**
  returns currently displayed top view controller.
 */
- (nullable UIViewController *)topMostViewController;

/**
 returns the current key window
 */
- (nullable UIWindow *)findWindow;

#pragma mark - FB Apps Installed

@property (nonatomic, readonly, assign) BOOL isMessengerAppInstalled;

- (BOOL)isRegisteredCanOpenURLScheme:(NSString *)urlScheme;

@end

NS_ASSUME_NONNULL_END
