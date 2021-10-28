/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FacebookGamingServices;

@interface FBSDKGamingPayload (Testing)

NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, readonly) NSString *gameRequestID;
@property (nonatomic, readonly) NSString *payload;

- (instancetype)initWithURL:(FBSDKURL *_Nonnull)url;

@end

NS_ASSUME_NONNULL_END
