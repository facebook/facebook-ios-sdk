/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit_Basics/FBSDKLinking.h>
#import <FBSDKCoreKit_Basics/FBSDKURLSessionProviding.h>

NS_ASSUME_NONNULL_BEGIN

FB_LINK_CATEGORY_IMPLEMENTATION(NSURLSession, URLSessionProviding)
@implementation NSURLSession (URLSessionProviding)

- (id<FBSDKNetworkTask>)fb_dataTaskWithRequest:(NSURLRequest *)request
                             completionHandler:(void (^)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))completionHandler
{
  return [self dataTaskWithRequest:request completionHandler:completionHandler];
}

@end

NS_ASSUME_NONNULL_END
