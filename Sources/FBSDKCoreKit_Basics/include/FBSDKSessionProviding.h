/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// An internal protocol used to describe a session data task
NS_SWIFT_NAME(SessionDataTask)
@protocol FBSDKSessionDataTask <NSObject>

@property (readonly) NSURLSessionTaskState state;

- (void)resume;
- (void)cancel;

@end

/// An internal protocol used to describe a url session
NS_SWIFT_NAME(SessionProviding)
@protocol FBSDKSessionProviding <NSObject>

- (id<FBSDKSessionDataTask>)dataTaskWithRequest:(NSURLRequest *)request
                              completionHandler:(void (^)(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
