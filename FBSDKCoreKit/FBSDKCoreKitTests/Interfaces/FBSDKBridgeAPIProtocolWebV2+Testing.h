/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKBridgeAPIProtocolWebV2.h"

@class FBSDKDialogConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKBridgeAPIProtocolWebV2 (Testing)

- (nullable NSURL *)_redirectURLWithActionID:(nullable NSString *)actionID
                                  methodName:(nullable NSString *)methodName
                                       error:(NSError **)errorRef;
- (nullable NSURL *)_requestURLForDialogConfiguration:(FBSDKDialogConfiguration *)dialogConfiguration
                                                error:(NSError **)errorRef;

@end

NS_ASSUME_NONNULL_END
