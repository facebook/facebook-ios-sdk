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

NS_PROTOCOL_REQUIRES_EXPLICIT_IMPLEMENTATION
NS_SWIFT_NAME(URLSessionProxying)
@protocol FBSDKURLSessionProxying

@property (nullable, nonatomic, retain) NSOperationQueue *delegateQueue;

- (void)executeURLRequest:(NSURLRequest *)request
        completionHandler:(FBSDKURLSessionTaskBlock)handler;
- (void)invalidateAndCancel;

@end

NS_ASSUME_NONNULL_END
