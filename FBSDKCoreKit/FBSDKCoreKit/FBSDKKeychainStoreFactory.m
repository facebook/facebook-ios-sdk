/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKKeychainStoreFactory.h"

#import "FBSDKKeychainStore.h"
#import "FBSDKKeychainStoreProtocol.h"

@implementation FBSDKKeychainStoreFactory

- (nonnull id<FBSDKKeychainStore>)createKeychainStoreWithService:(NSString *)service
                                                     accessGroup:(NSString *)accessGroup
{
  return [[FBSDKKeychainStore alloc] initWithService:(NSString *)service
                                         accessGroup:(NSString *)accessGroup];
}

@end
