/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Social/SLComposeViewController.h>

#import <FBSDKShareKit/_FBSDKSocialComposeViewController.h>
#import <FBSDKShareKit/_FBSDKSocialComposeViewControllerFactory.h>

@interface SLComposeViewController (FBSDKSocialComposeViewController) <_FBSDKSocialComposeViewController>
@end

@implementation _FBSDKSocialComposeViewControllerFactory

- (BOOL)canMakeSocialComposeViewController
{
  // iOS 11 returns NO for `isAvailableForServiceType` but it will still work
  NSOperatingSystemVersion iOS11Version = { .majorVersion = 11, .minorVersion = 0, .patchVersion = 0 };
  BOOL operatingSystemIsAdequate = [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:iOS11Version];
  BOOL composerIsAvailable = [SLComposeViewController isAvailableForServiceType:_FBSDKSocialComposeServiceType];
  return operatingSystemIsAdequate || composerIsAvailable;
}

- (nullable id<_FBSDKSocialComposeViewController>)makeSocialComposeViewController
{
  if (self.canMakeSocialComposeViewController) {
    return [SLComposeViewController composeViewControllerForServiceType:_FBSDKSocialComposeServiceType];
  } else {
    return nil;
  }
}

@end

#endif
