/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKServerConfigurationManager.h"
#import "FBSDKServerConfigurationProviding.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKServerConfigurationManager () <FBSDKServerConfigurationProviding>

@property (nullable, nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nullable, nonatomic) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;

- (void)processLoadRequestResponse:(nullable id)result error:(nullable NSError *)error appID:(NSString *)appID;

- (id<FBSDKGraphRequest>)requestToLoadServerConfiguration:(NSString *)appID;

- (void)clearCache;

@end

NS_ASSUME_NONNULL_END
