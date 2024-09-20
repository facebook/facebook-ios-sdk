/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit_Basics/FBSDKLinking.h>

NS_ASSUME_NONNULL_BEGIN

/// An internal protocol used to describe a network task
NS_SWIFT_NAME(NetworkTask)
@protocol FBSDKNetworkTask <NSObject>

@property (readonly) NSURLSessionTaskState fb_state;

- (void)fb_resume;
- (void)fb_cancel;

@end

FB_LINK_CATEGORY_INTERFACE(NSURLSessionTask, NetworkTask)
@interface NSURLSessionTask (NetworkTask) <FBSDKNetworkTask>

@end

NS_ASSUME_NONNULL_END
