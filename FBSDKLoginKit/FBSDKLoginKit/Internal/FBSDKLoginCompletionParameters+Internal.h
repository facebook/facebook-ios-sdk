/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKLoginCompletionParameters.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKLoginCompletionParameters ()

@property (nullable, nonatomic) FBSDKAuthenticationToken *authenticationToken;
@property (nullable, nonatomic) FBSDKProfile *profile;

@property (nullable, nonatomic, copy) NSString *accessTokenString;
@property (nullable, nonatomic, copy) NSString *nonceString;
@property (nullable, nonatomic, copy) NSString *authenticationTokenString;

@property (nullable, nonatomic, copy) NSSet<FBSDKPermission *> *permissions;
@property (nullable, nonatomic, copy) NSSet<FBSDKPermission *> *declinedPermissions;
@property (nullable, nonatomic, copy) NSSet<FBSDKPermission *> *expiredPermissions;

@property (nullable, nonatomic, copy) NSString *appID;
@property (nullable, nonatomic, copy) NSString *userID;

@property (nullable, nonatomic, copy) NSError *error;

@property (nullable, nonatomic, copy) NSDate *expirationDate;
@property (nullable, nonatomic, copy) NSDate *dataAccessExpirationDate;

@property (nullable, nonatomic, copy) NSString *challenge;

@property (nullable, nonatomic, copy) NSString *graphDomain;

@end

NS_ASSUME_NONNULL_END

#endif
