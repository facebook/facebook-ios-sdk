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
  // iOS 11 returns NO for `isAvailableForServiceType` but it will still work
  NSOperatingSystemVersion iOS11Version = { .majorVersion = 11, .minorVersion = 0, .patchVersion = 0 };
  BOOL operatingSystemIsAdequate = [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:iOS11Version];
  BOOL composerIsAvailable = [SLComposeViewController isAvailableForServiceType:FBSDKSocialComposeServiceType];
  return operatingSystemIsAdequate || composerIsAvailable;
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
