/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKContainerViewController;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_ContainerViewControllerDelegate)
@protocol FBSDKContainerViewControllerDelegate <NSObject>

- (void)viewControllerDidDisappear:(FBSDKContainerViewController *)viewController animated:(BOOL)animated;

@end

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_ContainerViewController)
@interface FBSDKContainerViewController : UIViewController

@property (nullable, nonatomic, weak) id<FBSDKContainerViewControllerDelegate> delegate;

- (void)displayChildController:(UIViewController *)childController;

@end

NS_ASSUME_NONNULL_END

#endif
