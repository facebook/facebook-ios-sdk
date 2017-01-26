// Copyright 2004-present Facebook. All Rights Reserved.
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

#import "ReverbActionBarView.h"

#import "ReverbTheme.h"

@implementation ReverbActionBarView

#pragma mark - Object Lifecycle

- (instancetype)initWithState:(AKFLoginFlowState)state
                        theme:(ReverbTheme *)theme
                     delegate:(id<ReverbActionBarViewDelegate>)delegate
{
  if ((self = [super initWithFrame:CGRectZero])) {
    self.delegate = delegate;

    self.backgroundColor = theme.headerBackgroundColor;

    UIButton *backButton = nil;
    UIImage *backArrowImage = theme.backArrowImage;
    if (backArrowImage != nil) {
      backButton = [[UIButton alloc] initWithFrame:CGRectZero];
      backButton.translatesAutoresizingMaskIntoConstraints = NO;
      [backButton setImage:backArrowImage forState:UIControlStateNormal];
      [backButton addTarget:self action:@selector(_back:) forControlEvents:UIControlEventTouchUpInside];
      [backButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
      [backButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
      [self addSubview:backButton];
    }

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.backgroundColor = theme.headerBackgroundColor;
    titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    titleLabel.text = [self _titleForState:state theme:theme];
    titleLabel.textColor = theme.headerTextColor;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:titleLabel];

    UIImageView *appIconView = nil;
    UIImage *appIconImage = theme.appIconImage;
    if (appIconImage != nil) {
      appIconView = [[UIImageView alloc] initWithImage:appIconImage];
      appIconView.contentMode = UIViewContentModeCenter;
      appIconView.translatesAutoresizingMaskIntoConstraints = NO;
      [appIconView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
      [appIconView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
      [self addSubview:appIconView];
    }

    NSDictionary<NSString *, id> *views = NSDictionaryOfVariableBindings(titleLabel);
    NSDictionary<NSString *, id> *metrics = @{
                                              @"top": @28.0,
                                              };
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[titleLabel]-|" options:0 metrics:metrics views:views]];
    if (backButton == nil) {
      [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[titleLabel]" options:0 metrics:nil views:views]];
    } else {
      NSDictionary<NSString *, id> *backButtonViews = NSDictionaryOfVariableBindings(backButton, titleLabel);
      [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[backButton]-[titleLabel]" options:0 metrics:nil views:backButtonViews]];
      [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[backButton]-|" options:0 metrics:metrics views:backButtonViews]];
    }
    if (appIconView == nil) {
      [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[titleLabel]-|" options:0 metrics:nil views:views]];
    } else {
      NSDictionary<NSString *, id> *appIconViews = NSDictionaryOfVariableBindings(appIconView, titleLabel);
      [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[titleLabel]-[appIconView]-|" options:0 metrics:nil views:appIconViews]];
      [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(top)-[appIconView]-|" options:0 metrics:metrics views:appIconViews]];
    }
  }
  return self;
}

#pragma mark - Layout

- (CGSize)intrinsicContentSize
{
  return CGSizeMake(UIViewNoIntrinsicMetric, 64.0);
}

#pragma mark - Helper Methods

- (void)_back:(id)sender
{
  [self.delegate reverbActionBarViewDidTapBack:self];
}

- (NSString *)_titleForState:(AKFLoginFlowState)state theme:(ReverbTheme *)theme
{
  NSString *title;
  switch (state) {
    case AKFLoginFlowStateNone:
    case AKFLoginFlowStateResendCode:
    case AKFLoginFlowStateCountryCode:
      return nil;
    case AKFLoginFlowStatePhoneNumberInput:
      title = @"Enter your phone number";
      break;
    case AKFLoginFlowStateEmailInput:
      title = @"Enter your email address";
      break;
    case AKFLoginFlowStateSendingCode:
      title = @"Sending your code...";
      break;
    case AKFLoginFlowStateSentCode:
      title = @"Sent!";
      break;
    case AKFLoginFlowStateCodeInput:
      title = @"Enter your code";
      break;
    case AKFLoginFlowStateEmailVerify:
      title = @"Open the email and confirm your address";
      break;
    case AKFLoginFlowStateVerifyingCode:
      title = @"Verifying your code...";
      break;
    case AKFLoginFlowStateVerified:
      title = @"Done!";
      break;
    case AKFLoginFlowStateError:
      title = @"We're sorry, something went wrong.";
      break;
  }
  if (theme.textUppercase) {
    title = [title uppercaseString];
  }
  return title;
}

@end
