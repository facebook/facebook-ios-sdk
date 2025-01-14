/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKGraphRequestConnection.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKGraphRequest;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 Used to facilitate FBSDKGraphRequest processing, specifically
 associating FBSDKGraphRequest and FBSDKGraphRequestBlock instances and necessary
 data for retry processing.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(GraphRequestMetadata)
@interface FBSDKGraphRequestMetadata : NSObject

@property (nonatomic, retain) id<FBSDKGraphRequest> request;
@property (nonatomic, copy) FBSDKGraphRequestCompletion completionHandler;
@property (nonatomic, copy) NSDictionary<NSString *, id> *batchParameters;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithRequest:(id<FBSDKGraphRequest>)request
              completionHandler:(nullable FBSDKGraphRequestCompletion)handler
                batchParameters:(nullable NSDictionary<NSString *, id> *)batchParameters
  NS_DESIGNATED_INITIALIZER;

- (void)invokeCompletionHandlerForConnection:(id<FBSDKGraphRequestConnecting>)connection
                                 withResults:(nullable id)results
                                       error:(nullable NSError *)error;
@end

NS_ASSUME_NONNULL_END
