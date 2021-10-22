/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKLoginCompletion.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKLoginCompletionParameters ()

@property (nonatomic) FBSDKAuthenticationToken *authenticationToken;
@property (nonatomic) FBSDKProfile *profile;

@property (nonatomic, copy) NSString *accessTokenString;
@property (nonatomic, copy) NSString *nonceString;
@property (nonatomic, copy) NSString *authenticationTokenString;

@property (nonatomic, copy) NSSet<FBSDKPermission *> *permissions;
@property (nonatomic, copy) NSSet<FBSDKPermission *> *declinedPermissions;
@property (nonatomic, copy) NSSet<FBSDKPermission *> *expiredPermissions;

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *userID;

@property (nonatomic, copy) NSError *error;

@property (nonatomic, copy) NSDate *expirationDate;
@property (nonatomic, copy) NSDate *dataAccessExpirationDate;

@property (nonatomic, copy) NSString *challenge;

@property (nonatomic, copy) NSString *graphDomain;

@end

NS_ASSUME_NONNULL_END

#endif
