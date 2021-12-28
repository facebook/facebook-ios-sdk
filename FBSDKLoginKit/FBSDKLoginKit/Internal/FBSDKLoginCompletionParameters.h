/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKPermission.h"

NS_ASSUME_NONNULL_BEGIN

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

NS_ASSUME_NONNULL_END

#endif
