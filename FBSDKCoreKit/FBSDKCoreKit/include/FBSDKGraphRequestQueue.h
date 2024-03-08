/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <FBSDKCoreKit/FBSDKGraphRequest.h>
#import <FBSDKCoreKit/FBSDKGraphRequestMetadata.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The `FBSDKGraphRequestQueue` allows for several graph requests to be queued
 for later execution as a batch request.
 */
NS_SWIFT_NAME(GraphRequestQueue)
@interface FBSDKGraphRequestQueue : NSObject

/**
 Gets the shared instance `FBSDKGraphRequestQueue` singleton
 */
+ (instancetype)sharedInstance;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (void)configureWithGraphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
  NS_SWIFT_NAME(configure(graphRequestConnectionFactory:));

/**
 @method

 This method adds an <FBSDKGraphRequest> with its completion handler into the queue.

 @param request       The request to be queued
 @param completion       A handler to call back when the request is executed.
 */
- (void)enqueueRequest:(id<FBSDKGraphRequest>)request
          completion:(FBSDKGraphRequestCompletion)completion;

/**
 Internal  method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.
 
 @warning INTERNAL - DO NOT USE
 */
- (void)enqueueRequests:(NSArray<FBSDKGraphRequestMetadata *> *)requests;

/**
 Internal  method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.
 
 @warning INTERNAL - DO NOT USE
 */
- (void)enqueueRequestMetadata:(FBSDKGraphRequestMetadata *)requestMetadata;

/**
 @method
 
 This method flushes the queue. All requests currently in the queue will be
 executed in a single batch request. The queue is then emptied.
 */
- (void)flush;

@end

NS_ASSUME_NONNULL_END
