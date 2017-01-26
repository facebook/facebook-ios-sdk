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

#import "ReverbUIManager.h"

#import "ReverbActionBarView.h"
#import "ReverbBodyView.h"
#import "ReverbFooterView.h"
#import "ReverbHeaderView.h"
#import "ReverbTheme.h"

@interface ReverbUIManager () <ReverbActionBarViewDelegate, ReverbFooterViewDelegate>
@end

@implementation ReverbUIManager
{
  id<AKFAdvancedUIActionController> _actionController;
}

- (instancetype)initWithConfirmButtonType:(AKFButtonType)confirmButtonType
                          entryButtonType:(AKFButtonType)entryButtonType
                                loginType:(AKFLoginType)loginType
                             textPosition:(AKFTextPosition)textPosition
                                    theme:(ReverbTheme *)theme
                                 delegate:(id<ReverbUIManagerDelegate>)delegate
{
  if ((self = [super init])) {
    _confirmButtonType = confirmButtonType;
    _entryButtonType = entryButtonType;
    _loginType = loginType;
    _textPosition = textPosition;
    _theme = [theme copy];
    _delegate = delegate;
  }
  return self;
}

#pragma mark - AKFAdvancedUIManager

- (nullable UIView *)actionBarViewForState:(AKFLoginFlowState)state
{
  return [[ReverbActionBarView alloc] initWithState:state theme:_theme delegate:self];
}

- (nullable UIView *)bodyViewForState:(AKFLoginFlowState)state
{
  UIImage *image = nil;
  BOOL shouldRotate = NO;
  switch (state) {
    case AKFLoginFlowStateSendingCode:
    case AKFLoginFlowStateVerifyingCode:
      image = [UIImage imageNamed:@"reverb-progress-ring"];
      shouldRotate = YES;
      break;
    case AKFLoginFlowStateSentCode:
      switch (_loginType) {
        case AKFLoginTypeEmail:
          image = [UIImage imageNamed:@"reverb-email"];
          break;
        case AKFLoginTypePhone:
          image = [UIImage imageNamed:@"reverb-progress-complete"];
          break;
      }
      break;
    case AKFLoginFlowStateEmailVerify:
      image = [UIImage imageNamed:@"reverb-email-sent"];
      break;
    case AKFLoginFlowStateVerified:
      image = [UIImage imageNamed:@"reverb-progress-complete"];
      break;
    case AKFLoginFlowStateError:
      image = [UIImage imageNamed:@"reverb-error"];
      break;
    case AKFLoginFlowStatePhoneNumberInput:
    case AKFLoginFlowStateEmailInput:
    case AKFLoginFlowStateCodeInput:
    case AKFLoginFlowStateNone:
    case AKFLoginFlowStateResendCode:
    case AKFLoginFlowStateCountryCode:
      return nil;
  }

  return [[ReverbBodyView alloc] initWithImage:image shouldRotate:shouldRotate];
}

- (AKFButtonType)buttonTypeForState:(AKFLoginFlowState)state
{
  switch (state) {
    case AKFLoginFlowStateCodeInput:
      return self.confirmButtonType;
    case AKFLoginFlowStateEmailInput:
    case AKFLoginFlowStatePhoneNumberInput:
      return self.entryButtonType;
    case AKFLoginFlowStateNone:
    case AKFLoginFlowStateError:
    case AKFLoginFlowStateSentCode:
    case AKFLoginFlowStateVerified:
    case AKFLoginFlowStateEmailVerify:
    case AKFLoginFlowStateSendingCode:
    case AKFLoginFlowStateVerifyingCode:
    case AKFLoginFlowStateCountryCode:
    case AKFLoginFlowStateResendCode:
      return AKFButtonTypeDefault;
  }
}

- (nullable UIView *)footerViewForState:(AKFLoginFlowState)state
{
  NSUInteger progress;
  BOOL showSwitchLoginType = NO;
  switch (state) {
    case AKFLoginFlowStatePhoneNumberInput:
    case AKFLoginFlowStateEmailInput:
      progress = 1;
      showSwitchLoginType = YES;
      break;
    case AKFLoginFlowStateSendingCode:
    case AKFLoginFlowStateSentCode:
      progress = 2;
      break;
    case AKFLoginFlowStateCodeInput:
    case AKFLoginFlowStateEmailVerify:
      progress = 3;
      break;
    case AKFLoginFlowStateVerifyingCode:
      progress = 4;
      break;
    case AKFLoginFlowStateVerified:
      progress = 5;
      break;
    case AKFLoginFlowStateError:
    case AKFLoginFlowStateResendCode:
    case AKFLoginFlowStateCountryCode:
    case AKFLoginFlowStateNone:
      return nil;
  }

  return [[ReverbFooterView alloc] initWithProgress:progress
                                        maxProgress:5
                                showSwitchLoginType:showSwitchLoginType
                                          loginType:_loginType
                                              theme:_theme
                                           delegate:self];
}

- (nullable UIView *)headerViewForState:(AKFLoginFlowState)state
{
  if (state == AKFLoginFlowStateError) {
    return nil;
  }

  ReverbHeaderView *view = [[ReverbHeaderView alloc] initWithFrame:CGRectZero];
  if ([_theme.headerBackgroundColor isEqual:_theme.backgroundColor]) {
    view.staticHeight = 8.0;
  } else {
    view.staticHeight = 32.0;
  }
  return view;
}

- (void)setActionController:(nonnull id<AKFAdvancedUIActionController>)actionController
{
  _actionController = actionController;
}

- (AKFTextPosition)textPositionForState:(AKFLoginFlowState)state
{
  return _textPosition == AKFTextPositionDefault ? AKFTextPositionAboveBody : _textPosition;
}

#pragma mark - ReverbActionBarViewDelegate

- (void)reverbActionBarViewDidTapBack:(ReverbActionBarView *)reverbActionBarView
{
  [_actionController back];
}

#pragma mark - ReverbFooterViewDelegate

- (void)reverbFooterViewDidTapSwitchLoginType:(ReverbFooterView *)reverbFooterView
{
  AKFLoginType newLoginType;
  switch (_loginType) {
    case AKFLoginTypeEmail:
      newLoginType = AKFLoginTypePhone;
      break;
    case AKFLoginTypePhone:
      newLoginType = AKFLoginTypeEmail;
      break;
  }
  [self.delegate reverbUIManager:self didSwitchLoginType:newLoginType];
  [_actionController cancel];
}

@end
