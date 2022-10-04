/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKObjectDecoding.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@protocol FBSDKUnarchiverProviding <NSObject>

+ (nonnull id<FBSDKObjectDecoding>)createSecureUnarchiverFor:(NSData *)data;
+ (nonnull id<FBSDKObjectDecoding>)createInsecureUnarchiverFor:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
