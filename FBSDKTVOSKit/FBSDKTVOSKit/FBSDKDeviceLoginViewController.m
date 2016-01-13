// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FBSDKDeviceLoginViewController.h"

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKDeviceLoginManager.h"
#import "FBSDKModalFormPresentationController.h"

static const NSTimeInterval kAnimationDurationTimeInterval = .5;

@interface FBSDKDeviceLoginViewController() <
  FBSDKDeviceLoginManagerDelegate,
  UIViewControllerAnimatedTransitioning,
  UIViewControllerTransitioningDelegate
>
@end

@implementation FBSDKDeviceLoginViewController {
  FBSDKDeviceLoginManager *_loginManager;
  UIActivityIndicatorView *_spinner;
  UILabel *_confirmationCodeLabel;
}

- (instancetype)init
{
  if ((self = [super init])) {
    self.transitioningDelegate = self;
    self.modalPresentationStyle = UIModalPresentationCustom;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self _buildView];

  NSArray<NSString *> *permissions = nil;
  if ((self.readPermissions).count > 0) {
    NSSet<NSString *> *permissionSet = [NSSet setWithArray:self.readPermissions];
    if ((self.publishPermissions).count > 0 || ![FBSDKInternalUtility areAllPermissionsReadPermissions:permissionSet]) {
      [[NSException exceptionWithName:NSInvalidArgumentException
                               reason:@"Read permissions are not permitted to be requested with publish or manage permissions."
                             userInfo:nil]
       raise];
    } else {
      permissions = self.readPermissions;
    }
  } else {
    NSSet<NSString *> *permissionSet = [NSSet setWithArray:self.publishPermissions];
    if (![FBSDKInternalUtility areAllPermissionsPublishPermissions:permissionSet]) {
      [[NSException exceptionWithName:NSInvalidArgumentException
                               reason:@"Publish or manage permissions are not permitted to be requested with read permissions."
                             userInfo:nil]
       raise];
    } else {
      permissions = self.publishPermissions;
    }
  }
  _loginManager = [[FBSDKDeviceLoginManager alloc] initWithPermissions:permissions];
  _loginManager.delegate = self;
  [_loginManager start];
}

- (void)dealloc
{
  _loginManager.delegate = nil;
  _loginManager = nil;
}

#pragma mark - FBSDKDeviceLoginManagerDelegate

- (void)deviceLoginManager:(FBSDKDeviceLoginManager *)loginManager startedWithCodeInfo:(FBSDKDeviceLoginCodeInfo *)codeInfo
{
  [_spinner stopAnimating];
  [_spinner removeFromSuperview];
  _confirmationCodeLabel.text = codeInfo.loginCode;
  _confirmationCodeLabel.hidden = NO;
}

- (void)deviceLoginManager:(FBSDKDeviceLoginManager *)loginManager completedWithResult:(FBSDKDeviceLoginManagerResult *)result error:(NSError *)error
{
  [self dismissViewControllerAnimated:YES completion:^{
    if (result.isCancelled) {
      [self _cancel];
    } else if (result.accessToken) {
      [FBSDKAccessToken setCurrentAccessToken:result.accessToken];
      [self.delegate deviceLoginViewControllerDidFinish:self];
    } else {
      [self.delegate deviceLoginViewControllerDidFail:self error:error];
    }
    // Go ahead and clear the delegate to avoid double messaging (i.e., since we're dismissing
    // ourselves we don't want a didFinish and then a didCancel (from viewWillDisappear).
    self.delegate = nil;
  }];
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

#pragma mark - Private impl

- (void)_buildView
{
  const CGFloat kWidth = 650;
  const CGFloat kHeight = 420;
  const CGFloat kVerticalSpaceBetweenHeaderViewAndInstructionLabel = 33;
  const CGFloat kVerticalSpaceBetweenInstructionLabelAndConfirmationCode = 33;
  const CGFloat kVerticalSpaceBetweenConfirmationCodeAndCancelButton = 32;
  const CGFloat kVerticalSpaceBetweenCancelButtonAndButtomAnchor = 39;
  const CGFloat kDialogHeaderViewHeight = 86;
  const CGFloat kLogoSize = 44;
  const CGFloat kLogoMargin = 29;
  const CGFloat kTitleHorizontalMargin = (kLogoMargin + kLogoSize + kLogoMargin);
  const CGFloat kInstructionTextHorizontalMargin = 120;
  const CGFloat kConfirmationCodeHeight = 42;

  // build the container view.
  UIView *dialogView = [[UIView alloc] init];
  dialogView.layer.cornerRadius = 3;
  dialogView.translatesAutoresizingMaskIntoConstraints = NO;
  dialogView.clipsToBounds = YES;
  [self.view addSubview:dialogView];
  [NSLayoutConstraint constraintWithItem:dialogView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0].active = YES;;
  [NSLayoutConstraint constraintWithItem:dialogView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0].active = YES;
  [dialogView.widthAnchor constraintEqualToConstant:kWidth].active = YES;
  [dialogView.heightAnchor constraintGreaterThanOrEqualToConstant:kHeight].active = YES;

  // build the header container view (which will contain the logo and title).
  UIView *dialogHeaderView = [[UIView alloc] init];
  dialogHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
  dialogHeaderView.backgroundColor = [UIColor colorWithRed:65.0/255.0 green:93.0/255.0 blue:174.0/255.0 alpha:0.85];
  [dialogView addSubview:dialogHeaderView];
  [dialogHeaderView.leadingAnchor constraintEqualToAnchor:dialogView.leadingAnchor].active = YES;
  [dialogHeaderView.trailingAnchor constraintEqualToAnchor:dialogView.trailingAnchor].active = YES;
  [dialogHeaderView.heightAnchor constraintGreaterThanOrEqualToConstant:kDialogHeaderViewHeight].active = YES;
  [dialogHeaderView.topAnchor constraintEqualToAnchor:dialogView.topAnchor].active = YES;

  // build the logo.
  CGSize imageSize = CGSizeMake(kLogoSize, kLogoSize);
  UIImage *image = [[[FBSDKLogo alloc] init] imageWithSize:imageSize];
  image = [image resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];
  UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
  imageView.translatesAutoresizingMaskIntoConstraints = NO;
  [dialogHeaderView addSubview:imageView];
  [imageView.widthAnchor constraintEqualToConstant:kLogoSize].active = YES;
  [imageView.heightAnchor constraintEqualToConstant:kLogoSize].active = YES;
  [imageView.leadingAnchor constraintEqualToAnchor:dialogHeaderView.leadingAnchor constant:kLogoMargin].active = YES;

  // build the title.
  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:29];
  titleLabel.numberOfLines = 0;
  titleLabel.text = NSLocalizedStringWithDefaultValue(@"LoginButton.LogInLong",
                                                      @"FacebookSDK",
                                                      [FBSDKInternalUtility bundleForStrings],
                                                      @"Log in with Facebook",
                                                      @"The long label for the FBSDKLoginButton when the user is currently logged out");
  titleLabel.textAlignment = NSTextAlignmentCenter;
  titleLabel.textColor = [UIColor whiteColor];
  [dialogHeaderView addSubview:titleLabel];
  [titleLabel.leadingAnchor constraintEqualToAnchor:dialogHeaderView.leadingAnchor constant:kTitleHorizontalMargin].active = YES;
  [titleLabel.trailingAnchor constraintEqualToAnchor:dialogHeaderView.trailingAnchor constant:kTitleHorizontalMargin * -1.0].active = YES;
  [titleLabel.topAnchor constraintEqualToAnchor:dialogHeaderView.topAnchor constant:10].active = YES;
  [titleLabel.bottomAnchor constraintEqualToAnchor:dialogHeaderView.bottomAnchor constant:-10].active = YES;
  [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:titleLabel attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0].active = YES;;

  // build the body container view (which goes right below the header)
  UIView *dialogBodyView = [[UIView alloc] init];
  dialogBodyView.translatesAutoresizingMaskIntoConstraints = NO;
  dialogBodyView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.85];
  [dialogView addSubview:dialogBodyView];
  [dialogBodyView.leadingAnchor constraintEqualToAnchor:dialogView.leadingAnchor].active = YES;
  [dialogBodyView.trailingAnchor constraintEqualToAnchor:dialogView.trailingAnchor].active = YES;
  [dialogBodyView.topAnchor constraintEqualToAnchor:dialogHeaderView.bottomAnchor].active = YES;
  [dialogBodyView.bottomAnchor constraintEqualToAnchor:dialogView.bottomAnchor].active = YES;

  // build the instructions UILabel
  UILabel *instructionLabel = [[UILabel alloc] init];
  instructionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  NSString *localizedFormatString = NSLocalizedStringWithDefaultValue(@"DeviceLogin.LogInPrompt",
                                                                      @"FacebookSDK",
                                                                      [FBSDKInternalUtility bundleForStrings],
                                                                      @"Visit %@ on your smartphone or computer and enter this code:",
                                                                      @"The format string for device login instructions");
  NSString *const deviceLoginURLString = @"facebook.com/device";
  NSString *instructionString = [NSString localizedStringWithFormat:localizedFormatString, deviceLoginURLString];
  NSMutableParagraphStyle *instructionLabelParagraphStyle = [[NSMutableParagraphStyle alloc] init];
  instructionLabelParagraphStyle.lineHeightMultiple = 1.1;
  NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:instructionString
                                                                                       attributes:@{ NSParagraphStyleAttributeName : instructionLabelParagraphStyle }];
  NSRange range = [instructionString rangeOfString:deviceLoginURLString];
  [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Medium" size:28] range:range];
  instructionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:28];
  instructionLabel.attributedText = attributedString;
  instructionLabel.numberOfLines = 0;
  instructionLabel.textAlignment = NSTextAlignmentCenter;
  [instructionLabel sizeToFit];
  instructionLabel.textColor = [UIColor grayColor];
  [dialogBodyView addSubview:instructionLabel];
  [instructionLabel.topAnchor constraintEqualToAnchor:dialogBodyView.topAnchor
                                             constant:kVerticalSpaceBetweenHeaderViewAndInstructionLabel].active = YES;
  [instructionLabel.leadingAnchor constraintEqualToAnchor:dialogBodyView.leadingAnchor constant:kInstructionTextHorizontalMargin].active = YES;
  [dialogBodyView.trailingAnchor constraintEqualToAnchor:instructionLabel.trailingAnchor constant:kInstructionTextHorizontalMargin].active = YES;

  // build the activity spinner
  _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  _spinner.translatesAutoresizingMaskIntoConstraints = NO;
  [dialogBodyView addSubview:_spinner];
  [NSLayoutConstraint constraintWithItem:_spinner attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:dialogBodyView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0].active = YES;;
  [_spinner.topAnchor constraintEqualToAnchor:instructionLabel.bottomAnchor
                                     constant:kVerticalSpaceBetweenInstructionLabelAndConfirmationCode].active = YES;
  [_spinner.widthAnchor constraintEqualToConstant:kConfirmationCodeHeight].active = YES;
  [_spinner.heightAnchor constraintEqualToConstant:kConfirmationCodeHeight].active = YES;
  [_spinner startAnimating];

  // build the confirmation code (which replaces the spinner when the code is available).
  _confirmationCodeLabel = [[UILabel alloc] init];
  _confirmationCodeLabel.translatesAutoresizingMaskIntoConstraints = NO;
  const CGFloat kConfirmationCodeTextColor = 74.0 / 255.0;
  _confirmationCodeLabel.textColor = [UIColor colorWithRed:kConfirmationCodeTextColor green:kConfirmationCodeTextColor blue:kConfirmationCodeTextColor alpha:1];
  _confirmationCodeLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:46];
  [dialogBodyView addSubview:_confirmationCodeLabel];
  [NSLayoutConstraint constraintWithItem:_confirmationCodeLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:dialogBodyView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0].active = YES;

  [_confirmationCodeLabel.topAnchor constraintEqualToAnchor:instructionLabel.bottomAnchor
                                                   constant:kVerticalSpaceBetweenInstructionLabelAndConfirmationCode].active = YES;
  [_confirmationCodeLabel.heightAnchor constraintEqualToConstant:kConfirmationCodeHeight].active = YES;
  [_confirmationCodeLabel.widthAnchor constraintGreaterThanOrEqualToConstant:kConfirmationCodeHeight].active = YES;
  _confirmationCodeLabel.hidden = YES;

  // build the container view for the cancel button.
  UIView *buttonContainerView = [[UIView alloc] init];
  buttonContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  [dialogBodyView addSubview:buttonContainerView];
  [buttonContainerView.widthAnchor constraintEqualToConstant:195].active = YES;
  [buttonContainerView.heightAnchor constraintEqualToConstant:54].active = YES;
  [NSLayoutConstraint constraintWithItem:buttonContainerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:dialogBodyView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0].active = YES;
  [buttonContainerView.topAnchor constraintEqualToAnchor:instructionLabel.bottomAnchor
                                                constant:(kVerticalSpaceBetweenInstructionLabelAndConfirmationCode +
                                                          kConfirmationCodeHeight +
                                                          kVerticalSpaceBetweenConfirmationCodeAndCancelButton)].active = YES;
    [dialogBodyView.bottomAnchor constraintEqualToAnchor:buttonContainerView.bottomAnchor
                                                constant:kVerticalSpaceBetweenCancelButtonAndButtomAnchor].active = YES;

  // build the cancel button.
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.layer.cornerRadius = 4.0;
  button.backgroundColor = [UIColor colorWithRed:(157.0/255.0) green:(163.0/255.0) blue:(177.0/255.0) alpha:1];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  [button setTitle:NSLocalizedStringWithDefaultValue(@"LoginButton.CancelLogout",
                                                     @"FacebookSDK",
                                                     [FBSDKInternalUtility bundleForStrings],
                                                     @"Cancel",
                                                     @"The label for the FBSDKLoginButton action sheet to cancel logging out")
          forState:UIControlStateNormal];
  button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:24];
  [button setTitleColor:[UIColor colorWithWhite:(248.0/255.0) alpha:1] forState:UIControlStateNormal];
  [buttonContainerView addSubview:button];
  [button.leadingAnchor constraintEqualToAnchor:buttonContainerView.leadingAnchor].active = YES;
  [button.trailingAnchor constraintEqualToAnchor:buttonContainerView.trailingAnchor].active = YES;
  [button.topAnchor constraintEqualToAnchor:buttonContainerView.topAnchor].active = YES;
  [button.bottomAnchor constraintEqualToAnchor:buttonContainerView.bottomAnchor].active = YES;
  const CGFloat kButtonFontColorValue = 119.0/255.0;
  button.titleLabel.textColor = [UIColor colorWithRed:kButtonFontColorValue green:kButtonFontColorValue blue:kButtonFontColorValue alpha:1.0];
  [button addTarget:self action:@selector(_cancelButtonTap:) forControlEvents:UIControlEventPrimaryActionTriggered];
}

- (void)_cancelButtonTap:(id)sender
{
  [self dismissViewControllerAnimated:YES completion:^{
    [self _cancel];
  }];
}

- (void)_cancel
{
  [_loginManager cancel];
  [self.delegate deviceLoginViewControllerDidCancel:self];
}

@end
