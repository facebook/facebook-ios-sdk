/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKURLSessionProxyFactory.h"

#import <Foundation/Foundation.h>

#import "FBSDKURLSession+Internal.h"

@implementation FBSDKURLSessionProxyFactory

- (nonnull id<FBSDKURLSessionProxying>)createSessionProxyWithDelegate:(id<NSURLSessionDataDelegate>)delegate
                                                                queue:(NSOperationQueue *)queue
{
  return [[FBSDKURLSession alloc] initWithDelegate:delegate delegateQueue:queue];
}

@end
