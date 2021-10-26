/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKImageDownloader.h"

@protocol FBSDKSessionProviding;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKImageDownloader (Testing)

@property (nonatomic, strong) id<FBSDKSessionProviding> sessionProvider;
@property (nonatomic, strong) NSURLCache *urlCache;

// UNCRUSTIFY_FORMAT_OFF
- (instancetype)initWithSessionProvider:(id<FBSDKSessionProviding>)sessionProvider
NS_SWIFT_NAME(init(sessionProvider:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END
