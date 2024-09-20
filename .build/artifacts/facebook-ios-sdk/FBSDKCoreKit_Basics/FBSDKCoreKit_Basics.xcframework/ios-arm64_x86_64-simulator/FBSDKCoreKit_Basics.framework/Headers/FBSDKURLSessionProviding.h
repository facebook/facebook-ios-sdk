/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit_Basics/FBSDKLinking.h>
#import <FBSDKCoreKit_Basics/FBSDKNetworkTask.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// An internal protocol used to describe a url session
NS_SWIFT_NAME(URLSessionProviding)
@protocol FBSDKURLSessionProviding <NSObject>

- (id<FBSDKNetworkTask>)fb_dataTaskWithRequest:(NSURLRequest *)request
                             completionHandler:(void (^)(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error))completionHandler;

@end

FB_LINK_CATEGORY_INTERFACE(NSURLSession, URLSessionProviding)
@interface NSURLSession (URLSessionProviding) <FBSDKURLSessionProviding>

@end

NS_ASSUME_NONNULL_END
