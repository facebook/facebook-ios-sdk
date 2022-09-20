/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKTVLoginViewControllerElement.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
@implementation FBSDKTVLoginViewControllerElement
#pragma clang diagnostic pop

- (void)deviceLoginViewControllerDidCancel:(FBSDKDeviceLoginViewController *)viewController
{
  [self dispatchEventWithName:@"onFacebookLoginViewControllerCancel"
                    canBubble:YES
                  cancellable:YES
                    extraInfo:nil
                   completion:NULL];
}

- (void)deviceLoginViewControllerDidFinish:(FBSDKDeviceLoginViewController *)viewController
{
  [self dispatchEventWithName:@"onFacebookLoginViewControllerFinish"
                    canBubble:YES
                  cancellable:YES
                    extraInfo:nil
                   completion:NULL];
}

- (void)deviceLoginViewController:(FBSDKDeviceLoginViewController *)viewController didFailWithError:(NSError *)error
{
  [self dispatchEventWithName:@"onFacebookLoginViewControllerError"
                    canBubble:YES
                  cancellable:YES
                    extraInfo:@{ @"error" : error }
                   completion:NULL];
}

@end
