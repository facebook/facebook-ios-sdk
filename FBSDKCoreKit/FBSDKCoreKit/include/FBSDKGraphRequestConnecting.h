/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
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

/**
 FBSDKGraphRequestCompletion

 A block that is passed to addRequest to register for a callback with the results of that
 request once the connection completes.

 Pass a block of this type when calling addRequest.  This will be called once
 the request completes.  The call occurs on the UI thread.

 @param connection The connection that sent the request.

 @param result The result of the request.  This is a translation of
 JSON data to `NSDictionary` and `NSArray` objects.  This
 is nil if there was an error.

 @param error The `NSError` representing any error that occurred.
 */
NS_SWIFT_NAME(GraphRequestCompletion)
typedef void (^FBSDKGraphRequestCompletion)(id<FBSDKGraphRequestConnecting> _Nullable connection,
                                            id _Nullable result,
                                            NSError *_Nullable error);

/// A protocol to describe an object that can manage graph requests
NS_SWIFT_NAME(GraphRequestConnecting)
@protocol FBSDKGraphRequestConnecting

@property (nonatomic, assign) NSTimeInterval timeout;
@property (nullable, nonatomic, weak) id<FBSDKGraphRequestConnectionDelegate> delegate;

- (void)addRequest:(id<FBSDKGraphRequest>)request
        completion:(FBSDKGraphRequestCompletion)handler;

- (void)start;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
