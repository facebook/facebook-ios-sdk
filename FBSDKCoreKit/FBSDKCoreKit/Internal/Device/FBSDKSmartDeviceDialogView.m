/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if TARGET_OS_TV

#import "FBSDKSmartDeviceDialogView.h"

#import "FBSDKDeviceUtilities.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKLogo.h"

@interface FBSDKSmartDeviceDialogView ()
@property (nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic) UILabel *confirmationCodeLabel;
@property (nonatomic) UIImageView *qrImageView;
@end

@implementation FBSDKSmartDeviceDialogView

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    [self _buildView];
  }
  return self;
}

#pragma mark - Overrides

- (void)setConfirmationCode:(NSString *)confirmationCode
{
  if (![self.confirmationCode isEqualToString:confirmationCode]) {
    if (confirmationCode == nil) {
      _confirmationCodeLabel.text = @"";
      _confirmationCodeLabel.hidden = YES;
      _qrImageView.hidden = YES;
      [_spinner startAnimating];
    } else {
      [_spinner stopAnimating];
      _confirmationCodeLabel.text = confirmationCode;
      _confirmationCodeLabel.hidden = NO;
      _qrImageView.hidden = NO;
      [_qrImageView setImage:[FBSDKDeviceUtilities buildQRCodeWithAuthorizationCode:confirmationCode]];
    }
  }
}

- (void)buildView
{
  // intentionally blank.
}

- (UIColor *)_logoColor
{
  return [UIColor colorWithRed:66.0 / 255.0 green:103.0 / 255.0 blue:178.0 / 255.0 alpha:1];
}

- (void)_buildView
{
  // This is a "static" view with just a cancel button so add all the constraints here
  // rather than properly override `updateConstraints`.
  const CGFloat kWidth = 1080;
  const CGFloat kVerticalSpaceBetweenHeaderViewAndInstructionLabel = 50;
  const CGFloat kDialogHeaderViewHeight = 250;
  const CGFloat kLogoSize = 44;
  const CGFloat kLogoMargin = 30;
  const CGFloat kInstructionTextHorizontalMargin = 100;
  const CGFloat kConfirmationCodeFontSize = 108;
  const CGFloat kFontColorValue = 119.0 / 255.0;
  const CGFloat kInstructionFontSize = 32;
  const CGFloat kVerticalMarginOrLabel = 40;
  const CGFloat kQRCodeSize = 200;
  const CGFloat kQRCodeMargin = (kWidth - kQRCodeSize) / 2;

  // build the container view.
  UIView *dialogView = [UIView new];
  dialogView.layer.cornerRadius = 3;
  dialogView.translatesAutoresizingMaskIntoConstraints = NO;
  dialogView.clipsToBounds = YES;
  dialogView.backgroundColor = UIColor.whiteColor;
  [self addSubview:dialogView];
  [NSLayoutConstraint constraintWithItem:dialogView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0].active = YES;;
  [NSLayoutConstraint constraintWithItem:dialogView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0].active = YES;
  [dialogView.widthAnchor constraintEqualToConstant:kWidth].active = YES;

  // build the header container view (which will contain the logo and code).
  UIView *dialogHeaderView = [UIView new];
  dialogHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
  dialogHeaderView.backgroundColor = [UIColor colorWithRed:226.0 / 255.0 green:231.0 / 255.0 blue:235.0 / 255.0 alpha:0.85];
  [dialogView addSubview:dialogHeaderView];
  [dialogHeaderView.leadingAnchor constraintEqualToAnchor:dialogView.leadingAnchor].active = YES;
  [dialogHeaderView.trailingAnchor constraintEqualToAnchor:dialogView.trailingAnchor].active = YES;
  [dialogHeaderView.heightAnchor constraintEqualToConstant:kDialogHeaderViewHeight].active = YES;
  [dialogHeaderView.topAnchor constraintEqualToAnchor:dialogView.topAnchor].active = YES;

  // build the logo.
  CGSize imageSize = CGSizeMake(kLogoSize, kLogoSize);
  FBSDKLogo *logoHelper = [FBSDKLogo new];
  UIImage *image = [logoHelper imageWithSize:imageSize color:self._logoColor];
  image = [image resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];
  UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
  imageView.translatesAutoresizingMaskIntoConstraints = NO;
  [dialogHeaderView addSubview:imageView];
  [imageView.widthAnchor constraintEqualToConstant:kLogoSize].active = YES;
  [imageView.heightAnchor constraintEqualToConstant:kLogoSize].active = YES;
  [imageView.topAnchor constraintEqualToAnchor:dialogHeaderView.topAnchor constant:kLogoMargin].active = YES;
  [imageView.leadingAnchor constraintEqualToAnchor:dialogHeaderView.leadingAnchor constant:kLogoMargin].active = YES;

  // build the activity spinner
  _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  _spinner.translatesAutoresizingMaskIntoConstraints = NO;
  [dialogHeaderView addSubview:_spinner];
  [NSLayoutConstraint constraintWithItem:_spinner attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:dialogHeaderView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0].active = YES;
  [NSLayoutConstraint constraintWithItem:_spinner attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:dialogHeaderView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0].active = YES;
  [_spinner.widthAnchor constraintEqualToConstant:kConfirmationCodeFontSize].active = YES;
  [_spinner.heightAnchor constraintEqualToConstant:kConfirmationCodeFontSize].active = YES;
  [_spinner startAnimating];

  // build the confirmation code (which replaces the spinner when the code is available).
  _confirmationCodeLabel = [UILabel new];
  _confirmationCodeLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _confirmationCodeLabel.textColor = self._logoColor;
  _confirmationCodeLabel.font = [UIFont systemFontOfSize:kConfirmationCodeFontSize weight:UIFontWeightLight];
  _confirmationCodeLabel.textAlignment = NSTextAlignmentCenter;
  [_confirmationCodeLabel sizeToFit];
  [dialogHeaderView addSubview:_confirmationCodeLabel];
  [NSLayoutConstraint constraintWithItem:_confirmationCodeLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:dialogHeaderView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0].active = YES;
  [NSLayoutConstraint constraintWithItem:_confirmationCodeLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:dialogHeaderView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0].active = YES;
  _confirmationCodeLabel.hidden = YES;

  // build the smartlogin instructions
  UILabel *smartInstructionLabel = [UILabel new];
  smartInstructionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  NSString *smartInstructionString = NSLocalizedStringWithDefaultValue(
    @"DeviceLogin.SmartLogInPrompt",
    @"FacebookSDK",
    [FBSDKInternalUtility.sharedUtility bundleForStrings],
    @"To connect your account, open the Facebook app on your mobile device and check for notifications.",
    @"Instructions telling the user to open their Facebook app on a mobile device and check for a login notification."
  );

  NSMutableParagraphStyle *instructionLabelParagraphStyle = [NSMutableParagraphStyle new];
  instructionLabelParagraphStyle.lineHeightMultiple = 1.3;
  NSMutableAttributedString *attributedSmartString = [[NSMutableAttributedString alloc] initWithString:smartInstructionString
                                                                                            attributes:@{ NSParagraphStyleAttributeName : instructionLabelParagraphStyle }];

  UIFont *instructionFont = [UIFont systemFontOfSize:kInstructionFontSize weight:UIFontWeightLight];
  smartInstructionLabel.font = instructionFont;
  smartInstructionLabel.attributedText = attributedSmartString;
  smartInstructionLabel.numberOfLines = 0;
  smartInstructionLabel.textAlignment = NSTextAlignmentCenter;
  [smartInstructionLabel sizeToFit];

  smartInstructionLabel.textColor = [UIColor colorWithWhite:kFontColorValue alpha:1.0];
  [dialogView addSubview:smartInstructionLabel];
  [smartInstructionLabel.topAnchor constraintEqualToAnchor:dialogHeaderView.bottomAnchor
                                                  constant:kVerticalSpaceBetweenHeaderViewAndInstructionLabel].active = YES;
  [smartInstructionLabel.leadingAnchor constraintEqualToAnchor:dialogView.leadingAnchor constant:kInstructionTextHorizontalMargin].active = YES;
  [dialogView.trailingAnchor constraintEqualToAnchor:smartInstructionLabel.trailingAnchor constant:kInstructionTextHorizontalMargin].active = YES;

  // build 'or' label
  UILabel *orInstructionLabel = [UILabel new];
  orInstructionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  orInstructionLabel.font = [UIFont systemFontOfSize:kInstructionFontSize weight:UIFontWeightBold];
  orInstructionLabel.text = NSLocalizedStringWithDefaultValue(
    @"DeviceLogin.SmartLogInOrLabel",
    @"FacebookSDK",
    [FBSDKInternalUtility.sharedUtility bundleForStrings],
    @"-- OR --",
    @"The 'or' string for smart login instructions"
  );;
  orInstructionLabel.numberOfLines = 0;
  orInstructionLabel.textAlignment = NSTextAlignmentCenter;
  [orInstructionLabel sizeToFit];
  orInstructionLabel.textColor = [UIColor colorWithWhite:kFontColorValue alpha:1.0];
  [dialogView addSubview:orInstructionLabel];
  [orInstructionLabel.topAnchor constraintEqualToAnchor:smartInstructionLabel.bottomAnchor constant:kVerticalMarginOrLabel].active = YES;

  [orInstructionLabel.leadingAnchor constraintEqualToAnchor:dialogView.leadingAnchor constant:kInstructionTextHorizontalMargin].active = YES;
  [dialogView.trailingAnchor constraintEqualToAnchor:orInstructionLabel.trailingAnchor constant:kInstructionTextHorizontalMargin].active = YES;

  // Build the QR code view
  _qrImageView = [[UIImageView alloc] initWithImage:[FBSDKDeviceUtilities buildQRCodeWithAuthorizationCode:NULL]];
  _qrImageView.translatesAutoresizingMaskIntoConstraints = NO;
  [dialogView addSubview:_qrImageView];

  [_qrImageView.topAnchor constraintEqualToAnchor:orInstructionLabel.bottomAnchor
                                         constant:kVerticalMarginOrLabel].active = YES;
  [_qrImageView.bottomAnchor constraintEqualToAnchor:_qrImageView.topAnchor
                                            constant:kQRCodeSize].active = YES;
  [_qrImageView.leadingAnchor constraintEqualToAnchor:dialogView.leadingAnchor
                                             constant:kQRCodeMargin].active = YES;
  [dialogView.trailingAnchor constraintEqualToAnchor:_qrImageView.trailingAnchor
                                            constant:kQRCodeMargin].active = YES;

  // build the instructions UILabel
  UILabel *instructionLabel = [UILabel new];
  instructionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  NSString *localizedFormatString = NSLocalizedStringWithDefaultValue(
    @"DeviceLogin.LogInPrompt",
    @"FacebookSDK",
    [FBSDKInternalUtility.sharedUtility bundleForStrings],
    @"Visit %@ and enter the code shown above.",
    @"The format string for device login instructions"
  );

  NSString *const deviceLoginURLString = @"facebook.com/device";
  NSString *instructionString = [NSString localizedStringWithFormat:localizedFormatString, deviceLoginURLString];
  NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:instructionString
                                                                                       attributes:@{ NSParagraphStyleAttributeName : instructionLabelParagraphStyle }];
  NSRange range = [instructionString rangeOfString:deviceLoginURLString];
  [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:kInstructionFontSize weight:UIFontWeightMedium] range:range];
  instructionLabel.font = instructionFont;
  instructionLabel.attributedText = attributedString;
  instructionLabel.numberOfLines = 0;
  instructionLabel.textAlignment = NSTextAlignmentCenter;
  [instructionLabel sizeToFit];
  instructionLabel.textColor = [UIColor colorWithWhite:kFontColorValue alpha:1.0];
  [dialogView addSubview:instructionLabel];
  [instructionLabel.topAnchor constraintEqualToAnchor:_qrImageView.bottomAnchor
                                             constant:kVerticalMarginOrLabel].active = YES;
  [instructionLabel.leadingAnchor constraintEqualToAnchor:dialogView.leadingAnchor
                                                 constant:kInstructionTextHorizontalMargin].active = YES;
  [dialogView.trailingAnchor constraintEqualToAnchor:instructionLabel.trailingAnchor
                                            constant:kInstructionTextHorizontalMargin].active = YES;

  // build the container view for the cancel button.
  UIView *buttonContainerView = [UIView new];
  buttonContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  [dialogView addSubview:buttonContainerView];
  [NSLayoutConstraint constraintWithItem:buttonContainerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:dialogView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0].active = YES;
  [buttonContainerView.heightAnchor constraintEqualToConstant:60].active = YES;
  [buttonContainerView.leadingAnchor constraintEqualToAnchor:dialogView.leadingAnchor
                                                    constant:400].active = YES;
  [dialogView.trailingAnchor constraintEqualToAnchor:buttonContainerView.trailingAnchor
                                            constant:400].active = YES;
  [buttonContainerView.topAnchor constraintEqualToAnchor:instructionLabel.bottomAnchor
                                                constant:kVerticalMarginOrLabel].active = YES;
  [dialogView.bottomAnchor constraintEqualToAnchor:buttonContainerView.bottomAnchor
                                          constant:kVerticalMarginOrLabel].active = YES;

  // build the cancel button.
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  button.layer.cornerRadius = 4.0;
  button.translatesAutoresizingMaskIntoConstraints = NO;
  [button setTitle:NSLocalizedStringWithDefaultValue(
    @"LoginButton.CancelLogout",
    @"FacebookSDK",
    [FBSDKInternalUtility.sharedUtility bundleForStrings],
    @"Cancel",
    @"The label for the FBSDKLoginButton action sheet to cancel logging out"
  )
          forState:UIControlStateNormal];
  button.titleLabel.font = instructionLabel.font;
  [buttonContainerView addSubview:button];
  [button.leadingAnchor constraintEqualToAnchor:buttonContainerView.leadingAnchor].active = YES;
  [button.trailingAnchor constraintEqualToAnchor:buttonContainerView.trailingAnchor].active = YES;
  [button.topAnchor constraintEqualToAnchor:buttonContainerView.topAnchor].active = YES;
  [button.bottomAnchor constraintEqualToAnchor:buttonContainerView.bottomAnchor].active = YES;
  [button setTitleColor:[UIColor colorWithWhite:kFontColorValue alpha:1] forState:UIControlStateNormal];

  [button addTarget:self action:@selector(_cancelButtonTap:) forControlEvents:UIControlEventPrimaryActionTriggered];
}

- (void)_cancelButtonTap:(id)sender
{
  [self.delegate deviceDialogViewDidCancel:self];
}

@end

#endif
