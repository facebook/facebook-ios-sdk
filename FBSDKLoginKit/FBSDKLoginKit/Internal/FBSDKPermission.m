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

#import "FBSDKPermission.h"

#ifdef FBSDKCOCOAPODS
 #import <FBSDKCoreKit/FBSDKCoreKit+Internal.h>
#else
 #import "FBSDKCoreKit+Internal.h"
#endif

@implementation FBSDKPermission

- (nullable instancetype)initWithString:(NSString *)string
{
  NSString *permission = [FBSDKTypeUtility stringValue:string];
  if (permission.length <= 0) {
    return nil;
  }

  NSCharacterSet *allowedSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz_"];
  if (![[string stringByTrimmingCharactersInSet:allowedSet] isEqualToString:@""]) {
    return nil;
  }

  if ((self = [super init])) {
    _value = permission;
  }
  return self;
}

+ (NSSet<FBSDKPermission *> *)permissionsFromRawPermissions:(NSSet<NSString *> *)rawPermissions
{
  NSMutableSet *permissions = NSMutableSet.new;

  for (NSString *rawPermission in rawPermissions) {
    FBSDKPermission *permission = [[FBSDKPermission alloc] initWithString:rawPermission];
    if (!permission) {
      return nil;
    }
    [permissions addObject:permission];
  }

  return permissions;
}

+ (NSSet<NSString *> *)rawPermissionsFromPermissions:(NSSet<FBSDKPermission *> *)permissions
{
  NSMutableSet *rawPermissions = NSMutableSet.new;

  for (FBSDKPermission *permission in permissions) {
    [rawPermissions addObject:permission.value];
  }

  return rawPermissions;
}

- (BOOL)isEqual:(id)obj
{
  if (![obj isKindOfClass:[FBSDKPermission class]]) {
    return NO;
  }

  FBSDKPermission *other = (FBSDKPermission *)obj;
  return [self.value isEqualToString:other.value];
}

- (NSString *)description
{
  return self.value;
}

- (NSUInteger)hash
{
  return self.value.hash;
}

@end
