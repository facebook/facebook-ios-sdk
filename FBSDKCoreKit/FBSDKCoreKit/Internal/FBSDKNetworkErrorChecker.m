/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKNetworkErrorChecker.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKNetworkErrorChecker

- (BOOL)isNetworkError:(NSError *)error
{
  NSError *innerError = error.userInfo[NSUnderlyingErrorKey];
  if (innerError && [self isNetworkError:innerError]) {
    return YES;
  }

  switch (error.code) {
    case NSURLErrorTimedOut:
    case NSURLErrorCannotFindHost:
    case NSURLErrorCannotConnectToHost:
    case NSURLErrorNetworkConnectionLost:
    case NSURLErrorDNSLookupFailed:
    case NSURLErrorNotConnectedToInternet:
    case NSURLErrorInternationalRoamingOff:
    case NSURLErrorCallIsActive:
    case NSURLErrorDataNotAllowed:
      return YES;
    default:
      return NO;
  }
}

@end

NS_ASSUME_NONNULL_END
