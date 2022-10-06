/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit_Basics/FBSDKURLSession.h>
#import <FBSDKCoreKit_Basics/FBSDKURLSessionProviding.h>

@implementation FBSDKURLSession

- (instancetype)initWithDelegate:(id<NSURLSessionDataDelegate>)delegate
                   delegateQueue:(NSOperationQueue *)queue
{
  if ((self = [super init])) {
    self.delegate = delegate;
    self.delegateQueue = queue;
  }
  return self;
}

- (void)executeURLRequest:(NSURLRequest *)request
        completionHandler:(FBSDKURLSessionTaskBlock)handler
{
  if (!self.valid) {
    [self updateSessionWithBlock:^{
      FBSDKURLSessionTask *task = [[FBSDKURLSessionTask alloc] initWithRequest:request fromSession:self.session completionHandler:handler];
      [task start];
    }];
  } else {
    FBSDKURLSessionTask *task = [[FBSDKURLSessionTask alloc] initWithRequest:request fromSession:self.session completionHandler:handler];
    [task start];
  }
}

- (void)updateSessionWithBlock:(dispatch_block_t)block
{
  if (!self.valid) {
    self.session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration
                                                 delegate:_delegate
                                            delegateQueue:_delegateQueue];
  }
  block();
}

- (void)invalidateAndCancel
{
  [self.session invalidateAndCancel];
  self.session = nil;
}

- (BOOL)valid
{
  return self.session != nil;
}

@end
