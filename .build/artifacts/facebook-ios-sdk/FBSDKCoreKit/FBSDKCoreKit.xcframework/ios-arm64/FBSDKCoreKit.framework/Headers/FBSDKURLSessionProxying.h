/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_PROTOCOL_REQUIRES_EXPLICIT_IMPLEMENTATION
NS_SWIFT_NAME(_URLSessionProxying)
@protocol FBSDKURLSessionProxying

@property (nullable, nonatomic, retain) NSOperationQueue *delegateQueue;

- (void)executeURLRequest:(NSURLRequest *)request
        completionHandler:(FBSDKURLSessionTaskBlock)handler;
- (void)invalidateAndCancel;

@end

NS_ASSUME_NONNULL_END
