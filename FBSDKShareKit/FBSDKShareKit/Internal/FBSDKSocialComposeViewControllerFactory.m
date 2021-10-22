/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKSocialComposeViewControllerFactory.h"

#import <Social/SLComposeViewController.h>

#import "FBSDKSocialComposeViewController.h"

@interface SLComposeViewController (FBSDKSocialComposeViewController) <FBSDKSocialComposeViewController>
@end

@implementation FBSDKSocialComposeViewControllerFactory

- (BOOL)canMakeSocialComposeViewController
{
  return [SLComposeViewController isAvailableForServiceType:FBSDKSocialComposeServiceType];
}

- (nullable id<FBSDKSocialComposeViewController>)makeSocialComposeViewController
{
  if (self.canMakeSocialComposeViewController) {
    return [SLComposeViewController composeViewControllerForServiceType:FBSDKSocialComposeServiceType];
  } else {
    return nil;
  }
}

@end

#endif
