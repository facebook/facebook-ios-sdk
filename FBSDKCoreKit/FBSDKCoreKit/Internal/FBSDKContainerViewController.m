/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKContainerViewController.h"

@implementation FBSDKContainerViewController

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  if ([self.delegate respondsToSelector:@selector(viewControllerDidDisappear:animated:)]) {
    [self.delegate viewControllerDidDisappear:self animated:animated];
  }
}

- (void)displayChildController:(UIViewController *)childController
{
  [self addChildViewController:childController];
  UIView *view = self.view;
  UIView *childView = childController.view;
  childView.translatesAutoresizingMaskIntoConstraints = NO;
  childView.frame = view.frame;
  [view addSubview:childView];

  [view addConstraints:
   @[
     [NSLayoutConstraint constraintWithItem:childView
                                  attribute:NSLayoutAttributeTop
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:view
                                  attribute:NSLayoutAttributeTop
                                 multiplier:1.0
                                   constant:0.0],

     [NSLayoutConstraint constraintWithItem:childView
                                  attribute:NSLayoutAttributeBottom
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:view
                                  attribute:NSLayoutAttributeBottom
                                 multiplier:1.0
                                   constant:0.0],

     [NSLayoutConstraint constraintWithItem:childView
                                  attribute:NSLayoutAttributeLeading
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:view
                                  attribute:NSLayoutAttributeLeading
                                 multiplier:1.0
                                   constant:0.0],

     [NSLayoutConstraint constraintWithItem:childView
                                  attribute:NSLayoutAttributeTrailing
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:view
                                  attribute:NSLayoutAttributeTrailing
                                 multiplier:1.0
                                   constant:0.0],
   ]];

  [childController didMoveToParentViewController:self];
}

@end

#endif
