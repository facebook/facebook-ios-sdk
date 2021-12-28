/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKURLSessionTask.h"

@implementation FBSDKURLSessionTask

- (instancetype)init
{
  if ((self = [super init])) {
    _requestStartDate = [NSDate date];
  }
  return self;
}

- (nullable instancetype)initWithRequest:(NSURLRequest *)request
                             fromSession:(id<FBSDKSessionProviding>)session
                       completionHandler:(nullable FBSDKURLSessionTaskBlock)handler
{
  if ((self = [self init])) {
    self.requestStartTime = (uint64_t)([self.requestStartDate timeIntervalSince1970] * 1000);
    self.task = [session dataTaskWithRequest:request completionHandler:handler];
  }
  return self;
}

- (NSURLSessionTaskState)state
{
  return self.task.state;
}

#pragma mark - Task State

- (void)start
{
  [self.task resume];
}

- (void)cancel
{
  [self.task cancel];
  self.handler = nil;
}

@end
