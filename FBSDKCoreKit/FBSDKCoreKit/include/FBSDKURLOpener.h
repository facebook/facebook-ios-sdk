/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKURLOpening;

NS_SWIFT_NAME(URLOpener)
@protocol FBSDKURLOpener

- (void)openURL:(NSURL *)url
         sender:(nullable id<FBSDKURLOpening>)sender
        handler:(FBSDKSuccessBlock)handler;

- (void)openURLWithSafariViewController:(NSURL *)url
                                 sender:(id<FBSDKURLOpening>)sender
                     fromViewController:(UIViewController *)fromViewController
                                handler:(FBSDKSuccessBlock)handler;

@end

NS_ASSUME_NONNULL_END
