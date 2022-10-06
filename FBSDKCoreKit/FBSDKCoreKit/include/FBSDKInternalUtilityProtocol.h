/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(InternalUtilityProtocol)
@protocol FBSDKInternalUtility

#pragma mark - FB Apps Installed

@property (nonatomic, readonly) BOOL isFacebookAppInstalled;

/*
 Checks if the app is Unity.
 */
@property (nonatomic, readonly) BOOL isUnity;

/**
 Constructs an NSURL.
 @param scheme The scheme for the URL.
 @param host The host for the URL.
 @param path The path for the URL.
 @param queryParameters The query parameters for the URL.  This will be converted into a query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return The URL.
 */
- (nullable NSURL *)URLWithScheme:(NSString *)scheme
                             host:(NSString *)host
                             path:(NSString *)path
                  queryParameters:(NSDictionary<NSString *, NSString *> *)queryParameters
                            error:(NSError *__autoreleasing *)errorRef;

/**
 Constructs an URL for the current app.
 @param host The host for the URL.
 @param path The path for the URL.
 @param queryParameters The query parameters for the URL.  This will be converted into a query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return The app URL.
 */
- (nullable NSURL *)appURLWithHost:(NSString *)host
                              path:(NSString *)path
                   queryParameters:(NSDictionary<NSString *, NSString *> *)queryParameters
                             error:(NSError *__autoreleasing *)errorRef;

/**
 Constructs a Facebook URL.
 @param hostPrefix The prefix for the host, such as 'm', 'graph', etc.
 @param path The path for the URL.  This may or may not include a version.
 @param queryParameters The query parameters for the URL.  This will be converted into a query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return The Facebook URL.
 */
- (nullable NSURL *)facebookURLWithHostPrefix:(NSString *)hostPrefix
                                         path:(NSString *)path
                              queryParameters:(NSDictionary<NSString *, NSString *> *)queryParameters
                                        error:(NSError *__autoreleasing *)errorRef
NS_SWIFT_NAME(facebookURL(hostPrefix:path:queryParameters:));

/**
 Registers a transient object so that it will not be deallocated until unregistered
 @param object The transient object
 */
- (void)registerTransientObject:(id)object;

/**
 Unregisters a transient object that was previously registered with registerTransientObject:
 @param object The transient object
 */
- (void)unregisterTransientObject:(__weak id)object;

- (void)checkRegisteredCanOpenURLScheme:(NSString *)urlScheme;

/// Validates that the right URL schemes are registered, throws an NSException if not.
- (void)validateURLSchemes;

/// add data processing options to the dictionary.
- (void)extendDictionaryWithDataProcessingOptions:(NSMutableDictionary<NSString *, NSString *> *)parameters;

/// Converts NSData to a hexadecimal UTF8 String.
- (nullable NSString *)hexadecimalStringFromData:(NSData *)data;

/// validates that the app ID is non-nil, throws an NSException if nil.
- (void)validateAppID;

/**
 Validates that the client access token is non-nil, otherwise - throws an NSException otherwise.
 Returns the composed client access token.
 */
- (NSString *)validateRequiredClientAccessToken;

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

/// validates that Facebook reserved URL schemes are not registered, throws an NSException if they are.
- (void)validateFacebookReservedURLSchemes;

/**
 Parses an FB url's query params (and potentially fragment) into a dictionary.
 @param url The FB url.
 @return A dictionary with the key/value pairs.
 */
- (NSDictionary<NSString *, id> *)parametersFromFBURL:(NSURL *)url;

/**
 Returns bundle for returning localized strings

 We assume a convention of a bundle named FBSDKStrings.bundle, otherwise we
 return the main bundle.
 */
@property (nonatomic, readonly, strong) NSBundle *bundleForStrings;

/// Returns currently displayed top view controller.
- (nullable UIViewController *)topMostViewController;

@end

NS_ASSUME_NONNULL_END
