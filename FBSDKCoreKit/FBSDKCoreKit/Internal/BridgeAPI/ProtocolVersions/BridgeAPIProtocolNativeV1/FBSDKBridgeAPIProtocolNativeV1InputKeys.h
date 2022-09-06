/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct {
  __unsafe_unretained NSString *bridgeArgs;
  __unsafe_unretained NSString *methodResults;
} FBSDKBridgeAPIProtocolNativeV1InputKeysStruct;
FOUNDATION_EXPORT const FBSDKBridgeAPIProtocolNativeV1InputKeysStruct FBSDKBridgeAPIProtocolNativeV1InputKeys;

NS_ASSUME_NONNULL_END

#endif
