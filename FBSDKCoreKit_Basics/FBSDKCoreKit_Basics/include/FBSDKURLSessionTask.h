/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit_Basics/FBSDKSessionProviding.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ FBSDKURLSessionTaskBlock)(NSData *_Nullable responseData,
  NSURLResponse *_Nullable response,
  NSError *_Nullable error)
NS_SWIFT_NAME(UrlSessionTaskBlock);

NS_SWIFT_NAME(UrlSessionTask)
@interface FBSDKURLSessionTask : NSObject

@property (nonatomic, strong) id<FBSDKSessionDataTask> task;
@property (atomic, readonly) NSURLSessionTaskState state;
@property (nonatomic, readonly, strong) NSDate *requestStartDate;
@property (nullable, nonatomic, copy) FBSDKURLSessionTaskBlock handler;
@property (nonatomic, assign) uint64_t requestStartTime;
@property (nonatomic, assign) NSUInteger loggerSerialNumber;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (nullable instancetype)initWithRequest:(NSURLRequest *)request
                             fromSession:(id<FBSDKSessionProviding>)session
                       completionHandler:(nullable FBSDKURLSessionTaskBlock)handler;

- (void)start;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
