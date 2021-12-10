/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKContainerViewController;

NS_SWIFT_NAME(ContainerViewControllerDelegate)
@protocol FBSDKContainerViewControllerDelegate <NSObject>

- (void)viewControllerDidDisappear:(FBSDKContainerViewController *)viewController animated:(BOOL)animated;

@end

NS_SWIFT_NAME(FBContainerViewController)
@interface FBSDKContainerViewController : UIViewController

@property (nullable, nonatomic, weak) id<FBSDKContainerViewControllerDelegate> delegate;

- (void)displayChildController:(UIViewController *)childController;

@end

NS_ASSUME_NONNULL_END

#endif
