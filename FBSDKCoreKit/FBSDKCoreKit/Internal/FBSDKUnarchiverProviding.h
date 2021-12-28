/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKObjectDecoding.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKUnarchiverProviding <NSObject>

+ (nonnull id<FBSDKObjectDecoding>)createSecureUnarchiverFor:(NSData *)data;
+ (nonnull id<FBSDKObjectDecoding>)createInsecureUnarchiverFor:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
