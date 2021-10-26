/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FacebookGamingServices/FBSDKContextDialogFactoryProtocols.h>

@protocol FBSDKAccessTokenProviding;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(CreateContextDialogFactory)
@interface FBSDKCreateContextDialogFactory : NSObject <FBSDKCreateContextDialogMaking>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithTokenProvider:(Class<FBSDKAccessTokenProviding>)tokenProvider;

@end

NS_ASSUME_NONNULL_END
