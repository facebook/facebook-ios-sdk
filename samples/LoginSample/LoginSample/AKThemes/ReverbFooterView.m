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

#import "ReverbFooterView.h"

#import "ReverbProgressBar.h"
#import "ReverbProgressDots.h"
#import "ReverbProgressView.h"
#import "ReverbTheme.h"

@implementation ReverbFooterView

#pragma mark - Object Lifecycle

- (instancetype)initWithProgress:(NSUInteger)progress
                     maxProgress:(NSUInteger)maxProgress
             showSwitchLoginType:(BOOL)showSwitchLoginType
                       loginType:(AKFLoginType)loginType
                           theme:(ReverbTheme *)theme
                        delegate:(id<ReverbFooterViewDelegate>)delegate
{
  if ((self = [super initWithFrame:CGRectZero])) {
    self.delegate = delegate;

    UIButton *switchLoginTypeButton = nil;
    if (showSwitchLoginType) {
      switchLoginTypeButton = [[UIButton alloc] initWithFrame:CGRectZero];
      switchLoginTypeButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
      [switchLoginTypeButton setTitle:[self _switchLoginTypeTitleForLoginType:loginType] forState:UIControlStateNormal];
      [switchLoginTypeButton setTitleColor:theme.buttonBackgroundColor forState:UIControlStateNormal];
      switchLoginTypeButton.translatesAutoresizingMaskIntoConstraints = NO;
      [switchLoginTypeButton addTarget:self action:@selector(_switchLoginType:) forControlEvents:UIControlEventTouchUpInside];
      [self addSubview:switchLoginTypeButton];
    }

    UIView<ReverbProgressView> *progressView = nil;
    switch (theme.progressMode) {
      case ReverbThemeProgressModeBar:
        progressView = [[ReverbProgressBar alloc] initWithFrame:CGRectZero];
        break;
      case ReverbThemeProgressModeDots:
        progressView = [[ReverbProgressDots alloc] initWithFrame:CGRectZero];
        break;
    }
    progressView.backgroundColor = [UIColor clearColor];
    progressView.maxProgress = maxProgress;
    progressView.opaque = NO;
    progressView.progress = progress;
    progressView.progressActiveColor = theme.progressActiveColor;
    progressView.progressInactiveColor = theme.progressInactiveColor;
    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:progressView];

    NSDictionary<NSString *, id> *metrics = @{
                                              @"bottom": @12.0,
                                              @"left": @(theme.contentMarginLeft),
                                              @"right": @(theme.contentMarginRight),
                                              @"top": @14.0,
                                              };
    NSDictionary<NSString *, id> *views = NSDictionaryOfVariableBindings(progressView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[progressView]-bottom-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-left-[progressView]-right-|" options:0 metrics:metrics views:views]];

    if (switchLoginTypeButton == nil) {
      [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[progressView]" options:0 metrics:metrics views:views]];
    } else {
      NSDictionary<NSString *, id> *switchLoginTypeButtonViews = NSDictionaryOfVariableBindings(switchLoginTypeButton, progressView);
      [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[switchLoginTypeButton]-[progressView]" options:0 metrics:metrics views:switchLoginTypeButtonViews]];
      [self addConstraints:@[
                             [NSLayoutConstraint constraintWithItem:switchLoginTypeButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0],
                             ]];
    }
  }
  return self;
}

#pragma mark - Helper Methods

- (void)_switchLoginType:(id)sender
{
  [self.delegate reverbFooterViewDidTapSwitchLoginType:self];
}

- (NSString *)_switchLoginTypeTitleForLoginType:(AKFLoginType)loginType
{
  switch (loginType) {
    case AKFLoginTypeEmail:
      return @"SIGN IN WITH PHONE";
    case AKFLoginTypePhone:
      return @"SIGN IN WITH EMAIL";
  }
}

@end
