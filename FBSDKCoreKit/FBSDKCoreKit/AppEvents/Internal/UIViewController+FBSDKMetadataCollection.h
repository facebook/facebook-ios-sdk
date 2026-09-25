/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit_Basics/FBSDKLinking.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FB_LINK_CATEGORY_INTERFACE(UIViewController, FBSDKMetadataCollection)
@interface UIViewController (FBSDKMetadataCollection)

- (void)fb_metadataCollectionViewDidAppear:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
