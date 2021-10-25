/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAppLinkURLFactory.h"

#import <Foundation/Foundation.h>

#import "FBSDKURL+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKAppLinkURLFactory : NSObject

- (id<FBSDKAppLinkURL>)createAppLinkURLWithURL:(NSURL *)url
{
  return [FBSDKURL URLWithURL:url];
}

@end

NS_ASSUME_NONNULL_END

#endif
