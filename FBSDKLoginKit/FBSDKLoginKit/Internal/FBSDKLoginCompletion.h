/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

@class FBSDKAuthenticationToken;
@class FBSDKLoginCompletionParameters;
@class FBSDKPermission;
@class FBSDKProfile;

@protocol FBSDKGraphRequestConnectionFactory;
@protocol FBSDKAuthenticationTokenCreating;

NS_ASSUME_NONNULL_BEGIN

/**
 Success Block
 */
typedef void (^ FBSDKLoginCompletionParametersBlock)(FBSDKLoginCompletionParameters *parameters)
NS_SWIFT_NAME(LoginCompletionParametersBlock);

/**
  Structured interface for accessing the parameters used to complete a log in request.
 If \c authenticationTokenString is non-<code>nil</code>, the authentication succeeded. If \c error is
 non-<code>nil</code> the request failed. If both are \c nil, the request was cancelled.
 */
NS_SWIFT_NAME(LoginCompletionParameters)
@interface FBSDKLoginCompletionParameters : NSObject

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithError:(NSError *)error;

@property (nullable, nonatomic, readonly) FBSDKAuthenticationToken *authenticationToken;
@property (nullable, nonatomic, readonly) FBSDKProfile *profile;

@property (nullable, nonatomic, readonly, copy) NSString *accessTokenString;
@property (nullable, nonatomic, readonly, copy) NSString *nonceString;
@property (nullable, nonatomic, readonly, copy) NSString *authenticationTokenString;

@property (nullable, nonatomic, readonly, copy) NSSet<FBSDKPermission *> *permissions;
@property (nullable, nonatomic, readonly, copy) NSSet<FBSDKPermission *> *declinedPermissions;
@property (nullable, nonatomic, readonly, copy) NSSet<FBSDKPermission *> *expiredPermissions;

@property (nullable, nonatomic, readonly, copy) NSString *appID;
@property (nullable, nonatomic, readonly, copy) NSString *userID;

@property (nullable, nonatomic, readonly, copy) NSError *error;

@property (nullable, nonatomic, readonly, copy) NSDate *expirationDate;
@property (nullable, nonatomic, readonly, copy) NSDate *dataAccessExpirationDate;

@property (nullable, nonatomic, readonly, copy) NSString *challenge;

@property (nullable, nonatomic, readonly, copy) NSString *graphDomain;

@end

NS_SWIFT_NAME(LoginCompleting)
@protocol FBSDKLoginCompleting

/**
  Invoke \p handler with the login parameters derived from the authentication result.
 See the implementing class's documentation for whether it completes synchronously or asynchronously.
 */
- (void)completeLoginWithHandler:(FBSDKLoginCompletionParametersBlock)handler;

/**
  Invoke \p handler with the login parameters derived from the authentication result.
 See the implementing class's documentation for whether it completes synchronously or asynchronously.
 */
- (void)completeLoginWithHandler:(FBSDKLoginCompletionParametersBlock)handler
                           nonce:(nullable NSString *)nonce;

@end

#pragma mark - Completers

/**
  Extracts the log in completion parameters from the \p parameters dictionary,
 which must contain the parsed result of the return URL query string.

 The \c user_id key is first used to derive the User ID. If that fails, \c signed_request
 is used.

 Completion occurs synchronously.
 */
NS_SWIFT_NAME(LoginURLCompleter)
@interface FBSDKLoginURLCompleter : NSObject <FBSDKLoginCompleting>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithURLParameters:(NSDictionary<NSString *, id> *)parameters
                                appID:(NSString *)appID
        graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
           authenticationTokenCreator:(id<FBSDKAuthenticationTokenCreating>)authenticationTokenCreator;

@end

NS_ASSUME_NONNULL_END

#endif
