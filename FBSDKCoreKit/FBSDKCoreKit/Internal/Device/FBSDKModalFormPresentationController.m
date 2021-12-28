/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if TARGET_OS_TV

#import "FBSDKModalFormPresentationController.h"

@interface FBSDKModalFormPresentationController ()

@property (nonatomic) UIView *dimmedView;

@end

@implementation FBSDKModalFormPresentationController

- (UIView *)dimmedView
{
  if (!_dimmedView) {
    _dimmedView = [[UIView alloc] initWithFrame:self.containerView.bounds];
    _dimmedView.backgroundColor = [UIColor colorWithWhite:0 alpha:.6];
  }
  return _dimmedView;
}

#pragma mark - UIPresentationController overrides

- (void)presentationTransitionWillBegin
{
  [self.containerView addSubview:[self dimmedView]];
  [self.containerView addSubview:[self presentedView]];
  [self.presentingViewController.transitionCoordinator
   animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
     [self dimmedView].alpha = 1.0;
   } completion:NULL];
}

- (void)presentationTransitionDidEnd:(BOOL)completed
{
  if (!completed) {
    [[self dimmedView] removeFromSuperview];
  }
}

- (void)dismissalTransitionWillBegin
{
  [self.presentingViewController.transitionCoordinator
   animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
     [self dimmedView].alpha = 0;
   } completion:NULL];
}

- (void)dismissalTransitionDidEnd:(BOOL)completed
{
  if (completed) {
    [[self dimmedView] removeFromSuperview];
  }
}

// technically not necessary for tvOS yet since there's no resizing.
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
                 [self dimmedView].frame = self.containerView.bounds;
               } completion:NULL];
}

@end

#endif
