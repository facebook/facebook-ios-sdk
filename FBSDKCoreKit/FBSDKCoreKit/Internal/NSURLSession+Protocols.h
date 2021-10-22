/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

NS_ASSUME_NONNULL_BEGIN

// MARK: Default Protocol Conformances

@interface NSURLSessionDataTask (FBSessionDataTask) <FBSDKSessionDataTask>
@end

@interface NSURLSession (SessionProviding) <FBSDKSessionProviding>
@end

NS_ASSUME_NONNULL_END
