/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKGraphRequest.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ServerConfigurationLoading)
@protocol FBSDKServerConfigurationLoading

- (void)processLoadRequestResponse:(id)result error:(nullable NSError *)error appID:(NSString *)appID;

- (nullable FBSDKGraphRequest *)requestToLoadServerConfiguration:(NSString *)appID;

@end

NS_ASSUME_NONNULL_END
