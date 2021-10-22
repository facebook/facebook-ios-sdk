/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKLoginManagerLoginResult+Internal.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@interface FBSDKLoginManagerLoginResult ()
@property (nonatomic) NSMutableDictionary<NSString *, id> *mutableLoggingExtras;
@end

@implementation FBSDKLoginManagerLoginResult

- (instancetype)initWithToken:(FBSDKAccessToken *)token
          authenticationToken:(FBSDKAuthenticationToken *)authenticationToken
                  isCancelled:(BOOL)isCancelled
           grantedPermissions:(NSSet<NSString *> *)grantedPermissions
          declinedPermissions:(NSSet<NSString *> *)declinedPermissions
{
  if ((self = [super init])) {
    _mutableLoggingExtras = [NSMutableDictionary dictionary];
    _token = token ? [token copy] : nil;
    _authenticationToken = authenticationToken;
    _isCancelled = isCancelled;
    _grantedPermissions = [grantedPermissions copy];
    _declinedPermissions = [declinedPermissions copy];
  }
  ;
  return self;
}

- (void)addLoggingExtra:(id)object forKey:(id<NSCopying>)key
{
  [FBSDKTypeUtility dictionary:_mutableLoggingExtras setObject:object forKey:key];
}

- (NSDictionary<NSString *, id> *)loggingExtras
{
  return [_mutableLoggingExtras copy];
}

@end

#endif
