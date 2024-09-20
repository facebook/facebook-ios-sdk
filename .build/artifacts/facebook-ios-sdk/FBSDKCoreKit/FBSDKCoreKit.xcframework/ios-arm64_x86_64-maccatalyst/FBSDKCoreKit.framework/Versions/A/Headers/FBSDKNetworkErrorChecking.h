/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_SWIFT_NAME(NetworkErrorChecking)
@protocol FBSDKNetworkErrorChecking

/**
 Checks whether an error is a network error.

 @param error An error that may or may not represent a network error.

 @return `YES` if the error represents a network error, otherwise `NO`.
 */
- (BOOL)isNetworkError:(NSError *)error;

@end
