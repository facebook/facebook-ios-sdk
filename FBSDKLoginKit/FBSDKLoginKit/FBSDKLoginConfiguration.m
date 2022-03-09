/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKLoginConfiguration.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import <FBSDKLoginKit/FBSDKLoginKit-Swift.h>

#import "FBSDKCodeVerifier.h"
#import "FBSDKNonceUtility.h"
#import "FBSDKPermission.h"

FBSDKLoginAuthType FBSDKLoginAuthTypeRerequest = @"rerequest";
FBSDKLoginAuthType FBSDKLoginAuthTypeReauthorize = @"reauthorize";

@interface FBSDKLoginConfiguration ()
@property (nullable, nonatomic, readwrite, copy) FBSDKLoginAuthType authType;
@end

@implementation FBSDKLoginConfiguration

- (nullable instancetype)initWithTracking:(FBSDKLoginTracking)tracking
{
  return [[FBSDKLoginConfiguration alloc] initWithPermissions:@[]
                                                     tracking:tracking];
}

- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                                    tracking:(FBSDKLoginTracking)tracking
{
  return [[FBSDKLoginConfiguration alloc] initWithPermissions:permissions
                                                     tracking:tracking
                                                        nonce:NSUUID.UUID.UUIDString];
}

- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                                    tracking:(FBSDKLoginTracking)tracking
                             messengerPageId:(nullable NSString *)messengerPageId
{
  return [[FBSDKLoginConfiguration alloc] initWithPermissions:permissions
                                                     tracking:tracking
                                                        nonce:NSUUID.UUID.UUIDString
                                              messengerPageId:messengerPageId];
}

- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                                    tracking:(FBSDKLoginTracking)tracking
                             messengerPageId:(nullable NSString *)messengerPageId
                                    authType:(nullable FBSDKLoginAuthType)authType
{
  return [[FBSDKLoginConfiguration alloc] initWithPermissions:permissions
                                                     tracking:tracking
                                                        nonce:NSUUID.UUID.UUIDString
                                              messengerPageId:messengerPageId
                                                     authType:authType];
}

- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                                    tracking:(FBSDKLoginTracking)tracking
                                       nonce:(NSString *)nonce
{
  return [[FBSDKLoginConfiguration alloc] initWithPermissions:permissions
                                                     tracking:tracking
                                                        nonce:nonce
                                              messengerPageId:nil];
}

- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                                    tracking:(FBSDKLoginTracking)tracking
                                       nonce:(NSString *)nonce
                             messengerPageId:(nullable NSString *)messengerPageId
{
  return [[FBSDKLoginConfiguration alloc] initWithPermissions:permissions
                                                     tracking:tracking
                                                        nonce:nonce
                                              messengerPageId:messengerPageId
                                                     authType:FBSDKLoginAuthTypeRerequest];
}

- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                                    tracking:(FBSDKLoginTracking)tracking
                                       nonce:(NSString *)nonce
                             messengerPageId:(nullable NSString *)messengerPageId
                                    authType:(nullable FBSDKLoginAuthType)authType
{
  return [self initWithPermissions:permissions
                          tracking:tracking
                             nonce:nonce
                   messengerPageId:messengerPageId
                          authType:authType
                      codeVerifier:FBSDKCodeVerifier.new];
}

- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                                    tracking:(FBSDKLoginTracking)tracking
                                       nonce:(NSString *)nonce
                             messengerPageId:(nullable NSString *)messengerPageId
                                    authType:(nullable FBSDKLoginAuthType)authType
                                codeVerifier:(FBSDKCodeVerifier *)codeVerifier
{
  if (![FBSDKNonceUtility isValidNonce:nonce]) {
    NSString *msg = [NSString stringWithFormat:@"Invalid nonce:%@ provided to login configuration. Returning nil.", nonce];
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                           logEntry:msg];
    return nil;
  }

  NSSet<FBSDKPermission *> *permissionsSet = [FBSDKPermission permissionsFromRawPermissions:[NSSet setWithArray:permissions]];
  if (!permissionsSet) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                           logEntry:@"Invalid combination of permissions provided to login configuration."];
    return nil;
  }

  if (authType != nil && [FBSDKLoginConfiguration authTypeForString:authType] == nil) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                           logEntry:@"Invalid auth_type provided to login configuration."];
    return nil;
  }

  if (!codeVerifier) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                           logEntry:@"Invalid code verifier provided to login configuration. Returning nil."];
    return nil;
  }

  if ((self = [super init])) {
    _requestedPermissions = permissionsSet;
    _tracking = tracking;
    _nonce = nonce;
    _messengerPageId = [FBSDKTypeUtility coercedToStringValue:messengerPageId];
    self.authType = authType;
    _codeVerifier = codeVerifier;
  }

  return self;
}

- (instancetype)init
{
  if ((self = [super init])) {
    _requestedPermissions = [NSSet set];
    _tracking = FBSDKLoginTrackingEnabled;
    _nonce = NSUUID.UUID.UUIDString;
    _messengerPageId = nil;
    self.authType = FBSDKLoginAuthTypeRerequest;
  }

  return self;
}

+ (nullable FBSDKLoginAuthType)authTypeForString:(NSString *)rawValue
{
  NSDictionary<NSString *, id> *map = @{
    (NSString *)FBSDKLoginAuthTypeRerequest : FBSDKLoginAuthTypeRerequest,
    (NSString *)FBSDKLoginAuthTypeReauthorize : FBSDKLoginAuthTypeReauthorize
  };

  return [FBSDKTypeUtility dictionary:map objectForKey:rawValue ofType:NSString.class];
}

@end

#endif
