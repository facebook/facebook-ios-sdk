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

 #import "FBSDKPermission.h"

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
                                       nonce:(NSString *)nonce
{
  if (![FBSDKNonceUtility isValidNonce:nonce]) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                       formatString:@"Invalid nonce:%@ provided to login configuration. Returning nil.", nonce];
    return nil;
  }

  NSSet<FBSDKPermission *> *permissionsSet = [FBSDKLoginConfiguration permissionsFromRawPermissions:[NSSet setWithArray:permissions] forTrackingPreference:tracking];
  if (!permissionsSet) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                       formatString:@"Invalid combination of permissions and tracking preference provided to login configuration. The only permissions allowed when `tracking` is `.limited` are 'email', 'public_profile', 'gaming_profile' and 'gaming_user_picture'. Returning nil."];
    return nil;
  }

  if ((self = [super init])) {
    _requestedPermissions = permissionsSet;
    _tracking = tracking;
    _nonce = nonce;
  }

  return self;
}

- (instancetype)init
{
  if ((self = [super init])) {
    _requestedPermissions = [NSSet set];
    _tracking = FBSDKLoginTrackingEnabled;
    _nonce = NSUUID.UUID.UUIDString;
  }

  return self;
}

+ (NSSet<FBSDKPermission *> *)permissionsFromRawPermissions:(NSSet<NSString *> *)permissions
                                      forTrackingPreference:(FBSDKLoginTracking)tracking
{
  switch (tracking) {
    case FBSDKLoginTrackingLimited: {
      NSSet<NSString *> *validPermissions = [NSSet setWithArray:@[
        @"email",
        @"public_profile",
        @"gaming_profile",
        @"gaming_user_picture",
                                             ]];
      NSSet *combined = [permissions setByAddingObjectsFromSet:validPermissions];

      if (permissions.count != 0 && combined.count > validPermissions.count) {
        return nil;
      }
      break;
    }
    case FBSDKLoginTrackingEnabled:
      break;
  }

  return [FBSDKPermission permissionsFromRawPermissions:permissions];
}

@end

#endif
