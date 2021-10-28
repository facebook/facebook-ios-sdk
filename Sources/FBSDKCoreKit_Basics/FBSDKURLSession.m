/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKURLSession.h"

#import <Foundation/Foundation.h>

// At some point this default conformance declaration needs to be moved out of
// this class and treated like the dependency it is.
@interface NSURLSession (SessionProviding) <FBSDKSessionProviding>
@end

@implementation FBSDKURLSession

// Deprecating the method requires it to be implemented.
// This should be removed in the next major release.
+ (instancetype)new
{
  return [super new];
}

// Deprecating the method requires it to be implemented.
// This should be removed in the next major release.
- (instancetype)init
{
  return [super init];
}

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
