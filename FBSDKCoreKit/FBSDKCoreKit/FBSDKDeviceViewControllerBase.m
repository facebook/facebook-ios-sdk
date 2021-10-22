/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if TARGET_OS_TV

#import "FBSDKDeviceViewControllerBase+Internal.h"

#import "FBSDKModalFormPresentationController.h"
#import "FBSDKServerConfigurationProvider.h"
#import "FBSDKSmartDeviceDialogView.h"

static const NSTimeInterval kAnimationDurationTimeInterval = .5;

/*
Subclasses should generally:
- override viewDidDisappear to handle cancellations
- assign `deviceDialogView.confirmationCode` to set the code
*/
@implementation FBSDKDeviceViewControllerBase

- (instancetype)init
{
  if ((self = [super init])) {
    self.transitioningDelegate = self;
    self.modalPresentationStyle = UIModalPresentationCustom;
  }
  return self;
}

- (void)loadView
{
  CGRect frame = [UIScreen mainScreen].bounds;
  FBSDKServerConfigurationProvider *provider = [FBSDKServerConfigurationProvider new];
  NSUInteger cachedSmartLoginOptions = [provider cachedSmartLoginOptions];
  NSUInteger smartLoginEnabledOption = 1 << 0;
  BOOL smartLoginEnabled = cachedSmartLoginOptions & smartLoginEnabledOption;
  FBSDKDeviceDialogView *deviceView =
  (smartLoginEnabled
    ? [[FBSDKSmartDeviceDialogView alloc] initWithFrame:frame]
    : [[FBSDKDeviceDialogView alloc] initWithFrame:frame]);
  deviceView.delegate = self;
  self.view = deviceView;
}

- (FBSDKDeviceDialogView *)deviceDialogView
{
  return (FBSDKDeviceDialogView *)self.view;
}

#pragma mark - UIViewControllerAnimatedTransitioning

// Extract this out to another class if we have other similar transitions.
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
  return kAnimationDurationTimeInterval;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
  if ([self isBeingPresented]) {
    UIView *presentedView = [transitionContext viewForKey:UITransitionContextToViewKey];
    // animate the view to slide in from bottom
    presentedView.center = CGPointMake(presentedView.center.x, presentedView.center.y + CGRectGetHeight(presentedView.bounds));
    UIView *containerView = [transitionContext containerView];
    [containerView addSubview:presentedView];
    [UIView animateWithDuration:kAnimationDurationTimeInterval
                          delay:0
         usingSpringWithDamping:1
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                       presentedView.center = CGPointMake(presentedView.center.x, presentedView.center.y - CGRectGetHeight(presentedView.bounds));
                     } completion:^(BOOL finished) {
                       [transitionContext completeTransition:finished];
                     }];
  } else {
    UIView *presentedView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    // animate the view to slide out to the bottom
    [UIView animateWithDuration:kAnimationDurationTimeInterval
                          delay:0
         usingSpringWithDamping:1
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                       presentedView.center = CGPointMake(presentedView.center.x, presentedView.center.y + CGRectGetHeight(presentedView.bounds));
                     } completion:^(BOOL finished) {
                       [transitionContext completeTransition:finished];
                     }];
  }
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
  return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
  return self;
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented
                                                      presentingViewController:(UIViewController *)presenting
                                                          sourceViewController:(UIViewController *)source
{
  return [[FBSDKModalFormPresentationController alloc] initWithPresentedViewController:presented
                                                              presentingViewController:presenting];
}

#pragma mark - FBSDKDeviceDialogViewDelegate

- (void)deviceDialogViewDidCancel:(FBSDKDeviceDialogView *)deviceDialogView
{
  [self dismissViewControllerAnimated:YES completion:NULL];
}

@end

#endif
