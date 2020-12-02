// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKLoginConfiguration.h"

 #import "FBSDKNonceUtility.h"

 #ifdef FBSDKCOCOAPODS
  #import <FBSDKCoreKit/FBSDKCoreKit+Internal.h>
 #else
  #import "FBSDKCoreKit+Internal.h"
 #endif

@implementation FBSDKLoginConfiguration

- (nullable instancetype)initWithBetaLoginExperience:(FBSDKBetaLoginExperience)betaLoginExperience
{
  return [[FBSDKLoginConfiguration alloc] initWithPermissions:@[]
                                          betaLoginExperience:betaLoginExperience];
}

- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                         betaLoginExperience:(FBSDKBetaLoginExperience)betaLoginExperience
{
  return [[FBSDKLoginConfiguration alloc] initWithPermissions:permissions
                                          betaLoginExperience:betaLoginExperience
                                                        nonce:NSUUID.UUID.UUIDString];
}

- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                         betaLoginExperience:(FBSDKBetaLoginExperience)betaLoginExperience
                                       nonce:(NSString *)nonce
{
  if (![FBSDKNonceUtility isValidNonce:nonce]) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                       formatString:@"Invalid nonce:%@ provided to login configuration. Returning nil.", nonce];
    return nil;
  }

  NSSet<NSString *> *permissionsSet = [NSSet setWithArray:permissions];
  BOOL arePermissionsValid = [FBSDKLoginConfiguration _arePermissionsValid:permissionsSet
                                              forBetaLoginExperienceStatus:betaLoginExperience];
  if (!arePermissionsValid) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                       formatString:@"Invalid combination of permissions and beta experience preference provided to login configuration. The only permissions allowed when the `betaLoginExperince` is `.restricted` are 'email' and 'public_profile'. Returning nil."];
    return nil;
  }

  if ((self = [super init])) {
    _requestedPermissions = permissionsSet;
    _betaLoginExperience = betaLoginExperience;
    _nonce = nonce;
  }

  return self;
}

- (instancetype)init
{
  if ((self = [super init])) {
    _requestedPermissions = [NSSet set];
    _betaLoginExperience = FBSDKBetaLoginExperienceEnabled;
    _nonce = NSUUID.UUID.UUIDString;
  }

  return self;
}

+ (BOOL)  _arePermissionsValid:(NSSet<NSString *> *)permissions
  forBetaLoginExperienceStatus:(FBSDKBetaLoginExperience)betaLoginExperience
{
  if (betaLoginExperience == FBSDKBetaLoginExperienceRestricted) {
    NSSet<NSString *> *validPermissions = [NSSet setWithArray:@[@"email", @"public_profile"]];
    NSSet *combined = [permissions setByAddingObjectsFromSet:validPermissions];

    return (permissions.count == 0) || (combined.count <= validPermissions.count);
  }

  return YES;
}

@end

#endif
