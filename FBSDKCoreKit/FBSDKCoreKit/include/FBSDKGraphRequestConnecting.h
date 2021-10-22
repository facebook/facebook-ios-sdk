/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKGraphRequest;
@protocol FBSDKGraphRequestConnecting;
@protocol FBSDKGraphRequestConnectionDelegate;

NS_SWIFT_NAME(GraphRequestCompletion)
typedef void (^FBSDKGraphRequestCompletion)(id<FBSDKGraphRequestConnecting> _Nullable connection,
                                            id _Nullable result,
                                            NSError *_Nullable error);

/// A protocol to describe an object that can manage graph requests
NS_SWIFT_NAME(GraphRequestConnecting)
@protocol FBSDKGraphRequestConnecting

@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, weak, nullable) id<FBSDKGraphRequestConnectionDelegate> delegate;

- (void)addRequest:(id<FBSDKGraphRequest>)request
        completion:(FBSDKGraphRequestCompletion)handler;

- (void)start;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
