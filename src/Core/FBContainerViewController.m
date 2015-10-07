/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#import "FBContainerViewController.h"

@implementation FBContainerViewController

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
  childView.frame = view.bounds;
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
