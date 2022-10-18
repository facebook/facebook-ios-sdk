/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKGraphRequestConnecting.h>
#import <FBSDKCoreKit/FBSDKGraphRequestConnectionFactoryProtocol.h>
#import <FBSDKCoreKit/FBSDKGraphRequestHTTPMethod.h>
#import <FBSDKCoreKit/FBSDKGraphRequestProtocol.h>
#import <FBSDKCoreKit/FBSDKTokenStringProviding.h>

@protocol FBSDKSettings;

NS_ASSUME_NONNULL_BEGIN
/**
 Represents a request to the Facebook Graph API.

 `FBSDKGraphRequest` encapsulates the components of a request (the
 Graph API path, the parameters, error recovery behavior) and should be
 used in conjunction with `FBSDKGraphRequestConnection` to issue the request.

 Nearly all Graph APIs require an access token. Unless specified, the
 `[FBSDKAccessToken currentAccessToken]` is used. Therefore, most requests
 will require login first (see `FBSDKLoginManager` in FBSDKLoginKit.framework).

 A `- start` method is provided for convenience for single requests.

 By default, FBSDKGraphRequest will attempt to recover any errors returned from
 Facebook. You can disable this via `disableErrorRecovery:`.

 See FBSDKGraphErrorRecoveryProcessor
 */
NS_SWIFT_NAME(GraphRequest)
@interface FBSDKGraphRequest : NSObject <FBSDKGraphRequest>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
// UNCRUSTIFY_FORMAT_OFF
+ (void)     configureWithSettings:(id<FBSDKSettings>)settings
  currentAccessTokenStringProvider:(Class<FBSDKTokenStringProviding>)accessTokenProvider
     graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)_graphRequestConnectionFactory
NS_SWIFT_NAME(configure(settings:currentAccessTokenStringProvider:graphRequestConnectionFactory:));
// UNCRUSTIFY_FORMAT_ON

/**
 Initializes a new instance that use use `[FBSDKAccessToken currentAccessToken]`.
 @param graphPath the graph path (e.g., @"me").
 */
- (instancetype)initWithGraphPath:(NSString *)graphPath;

/**
 Initializes a new instance that use use `[FBSDKAccessToken currentAccessToken]`.
 @param graphPath the graph path (e.g., @"me").
 @param method the HTTP method. Empty String defaults to @"GET".
 */
- (instancetype)initWithGraphPath:(NSString *)graphPath
                       HTTPMethod:(FBSDKHTTPMethod)method;

/**
 Initializes a new instance that use use `[FBSDKAccessToken currentAccessToken]`.
 @param graphPath the graph path (e.g., @"me").
 @param parameters the optional parameters dictionary.
 */
- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(NSDictionary<NSString *, id> *)parameters;

/**
 Initializes a new instance that use use `[FBSDKAccessToken currentAccessToken]`.
 @param graphPath the graph path (e.g., @"me").
 @param parameters the optional parameters dictionary.
 @param method the HTTP method. Empty String defaults to @"GET".
 */
- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(NSDictionary<NSString *, id> *)parameters
                       HTTPMethod:(FBSDKHTTPMethod)method;

/**
 Initializes a new instance.
 @param graphPath the graph path (e.g., @"me").
 @param parameters the optional parameters dictionary.
 @param tokenString the token string to use. Specifying nil will cause no token to be used.
 @param version the optional Graph API version (e.g., @"v2.0"). nil defaults to `[FBSDKSettings graphAPIVersion]`.
 @param method the HTTP method. Empty String defaults to @"GET".
 */
- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(NSDictionary<NSString *, id> *)parameters
                      tokenString:(nullable NSString *)tokenString
                          version:(nullable NSString *)version
                       HTTPMethod:(FBSDKHTTPMethod)method
  NS_DESIGNATED_INITIALIZER;

/**
 Initializes a new instance.
 @param graphPath the graph path (e.g., @"me").
 @param parameters the optional parameters dictionary.
 @param requestFlags  flags that indicate how a graph request should be treated in various scenarios
 */
- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(nullable NSDictionary<NSString *, id> *)parameters
                            flags:(FBSDKGraphRequestFlags)requestFlags;

/**
 Initializes a new instance.
 @param graphPath the graph path (e.g., @"me").
 @param parameters the optional parameters dictionary.
 @param tokenString the token string to use. Specifying nil will cause no token to be used.
 @param HTTPMethod  the HTTP method. Empty String defaults to @"GET".
 @param flags  flags that indicate how a graph request should be treated in various scenarios
 */
- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(nullable NSDictionary<NSString *, id> *)parameters
                      tokenString:(nullable NSString *)tokenString
                       HTTPMethod:(nullable NSString *)HTTPMethod
                            flags:(FBSDKGraphRequestFlags)flags;

/// The request parameters.
@property (nonatomic, copy) NSDictionary<NSString *, id> *parameters;

/// The access token string used by the request.
@property (nullable, nonatomic, readonly, copy) NSString *tokenString;

/// The Graph API endpoint to use for the request, for example "me".
@property (nonatomic, readonly, copy) NSString *graphPath;

/// The HTTPMethod to use for the request, for example "GET" or "POST".
@property (nonatomic, readonly, copy) FBSDKHTTPMethod HTTPMethod;

/// The Graph API version to use (e.g., "v2.0")
@property (nonatomic, readonly, copy) NSString *version;

/**
 If set, disables the automatic error recovery mechanism.
 @param disable whether to disable the automatic error recovery mechanism

 By default, non-batched FBSDKGraphRequest instances will automatically try to recover
 from errors by constructing a `FBSDKGraphErrorRecoveryProcessor` instance that
 re-issues the request on successful recoveries. The re-issued request will call the same
 handler as the receiver but may occur with a different `FBSDKGraphRequestConnection` instance.

 This will override [FBSDKSettings setGraphErrorRecoveryDisabled:].
 */

// UNCRUSTIFY_FORMAT_OFF
- (void)setGraphErrorRecoveryDisabled:(BOOL)disable
NS_SWIFT_NAME(setGraphErrorRecovery(disabled:));
// UNCRUSTIFY_FORMAT_ON

/**
 Starts a connection to the Graph API.
 @param completion The handler block to call when the request completes.
 */
- (id<FBSDKGraphRequestConnecting>)startWithCompletion:(nullable FBSDKGraphRequestCompletion)completion;

@end

NS_ASSUME_NONNULL_END
