/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKURLSessionTask.h"

#import <FBSDKCoreKit_Basics/FBSDKNetworkTask.h>
#import <FBSDKCoreKit_Basics/FBSDKURLSessionProviding.h>

@implementation FBSDKURLSessionTask

- (instancetype)init
{
  if ((self = [super init])) {
    _requestStartDate = [NSDate date];
  }
  return self;
}

- (nullable instancetype)initWithRequest:(NSURLRequest *)request
                             fromSession:(id<FBSDKURLSessionProviding>)session
                       completionHandler:(nullable FBSDKURLSessionTaskBlock)handler
{
  if ((self = [self init])) {
    self.requestStartTime = (uint64_t)([self.requestStartDate timeIntervalSince1970] * 1000);
    self.task = [session fb_dataTaskWithRequest:request completionHandler:handler];
  }
  return self;
}

- (NSURLSessionTaskState)state
{
  return self.task.fb_state;
}

#pragma mark - Task State

- (void)start
{
  [self.task fb_resume];
}

- (void)cancel
{
  [self.task fb_cancel];
  self.handler = nil;
}

@end
