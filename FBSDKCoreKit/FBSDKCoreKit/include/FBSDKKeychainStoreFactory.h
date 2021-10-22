/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKKeychainStoreProviding.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type not intended for use outside of the SDKs.

 A factory for providing objects that conform to `KeychainStore`
*/
NS_SWIFT_NAME(KeychainStoreFactory)
@interface FBSDKKeychainStoreFactory : NSObject <FBSDKKeychainStoreProviding>
@end

NS_ASSUME_NONNULL_END
