/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit_Basics/FBSDKURLSessionTask.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKURLSession : NSObject

@property (nullable, atomic, strong) NSURLSession *session;
@property (nullable, nonatomic, weak) id<NSURLSessionDataDelegate> delegate;
@property (nullable, nonatomic, retain) NSOperationQueue *delegateQueue;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDelegate:(id<NSURLSessionDataDelegate>)delegate
                   delegateQueue:(NSOperationQueue *)delegateQueue;

- (void)executeURLRequest:(NSURLRequest *)request
        completionHandler:(FBSDKURLSessionTaskBlock)handler;

- (void)updateSessionWithBlock:(dispatch_block_t)block;

- (void)invalidateAndCancel;

- (BOOL)valid;

@end

NS_ASSUME_NONNULL_END
