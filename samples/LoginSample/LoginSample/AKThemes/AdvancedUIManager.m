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

#import "AdvancedUIManager.h"

#import "PlaceholderView.h"

@implementation AdvancedUIManager
{
  id<AKFAdvancedUIActionController> _actionController;
  NSError *_error;
}

#pragma mark - Object Lifecycle

- (instancetype)initWithConfirmButtonType:(AKFButtonType)confirmButtonType
                          entryButtonType:(AKFButtonType)entryButtonType
                                loginType:(AKFLoginType)loginType
                             textPosition:(AKFTextPosition)textPosition
{
  if ((self = [super init])) {
    _confirmButtonType = confirmButtonType;
    _entryButtonType = entryButtonType;
    _textPosition = textPosition;
    _loginType = loginType;
  }
  return self;
}

#pragma mark - AKFAdvancedUIManager

- (UIView *)actionBarViewForState:(AKFLoginFlowState)state
{
  PlaceholderView *view = [self _viewForState:state suffix:@"Action Bar" intrinsicHeight:64.0];
  view.contentInset = UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0);
  [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_back:)]];
  return view;
}

- (UIView *)bodyViewForState:(AKFLoginFlowState)state
{
  return [self _viewForState:state suffix:@"Body" intrinsicHeight:80.0];
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

- (UIView *)footerViewForState:(AKFLoginFlowState)state
{
  return [self _viewForState:state suffix:@"Footer" intrinsicHeight:120.0];
}

- (UIView *)headerViewForState:(AKFLoginFlowState)state
{
  if (state == AKFLoginFlowStateError) {
    NSString *errorMessage = _error.userInfo[AKFErrorUserMessageKey] ?: @"An error has occurred.";
    return [self _viewWithText:errorMessage intrinsicHeight:80.0];
  }
  return [self _viewForState:state suffix:@"Header" intrinsicHeight:80.0];
}

- (void)setActionController:(id<AKFAdvancedUIActionController>)actionController
{
  _actionController = actionController;
}

- (void)setError:(NSError *)error
{
  _error = [error copy];
}

- (AKFTextPosition)textPositionForState:(AKFLoginFlowState)state
{
  return _textPosition;
}

#pragma mark - Helper Methods

- (void)_back:(id)sender
{
  [_actionController back];
}

- (PlaceholderView *)_viewForState:(AKFLoginFlowState)state
                            suffix:(NSString *)suffix
                   intrinsicHeight:(CGFloat)intrinsicHeight
{
  NSString *prefix;
  switch (state) {
    case AKFLoginFlowStatePhoneNumberInput:
      prefix = @"Custom Phone Number";
      break;
    case AKFLoginFlowStateEmailInput:
      prefix = @"Custom Email";
      break;
    case AKFLoginFlowStateEmailVerify:
      prefix = @"Custom Email Verify";
      break;
    case AKFLoginFlowStateSendingCode:
      switch (_loginType) {
        case AKFLoginTypeEmail:
          prefix = @"Custom Sending Email";
          break;
        case AKFLoginTypePhone:
          prefix = @"Custom Sending Code";
          break;
      }
      break;
    case AKFLoginFlowStateSentCode:
      switch (_loginType) {
        case AKFLoginTypeEmail:
          prefix = @"Custom Sent Email";
          break;
        case AKFLoginTypePhone:
          prefix = @"Custom Sent Code";
          break;
      }
      break;
    case AKFLoginFlowStateCodeInput:
      prefix = @"Custom Code Input";
      break;
    case AKFLoginFlowStateVerifyingCode:
      prefix = @"Custom Verifying Code";
      break;
    case AKFLoginFlowStateVerified:
      prefix = @"Custom Verified";
      break;
    case AKFLoginFlowStateError:
      prefix = @"Custom Error";
      break;
    case AKFLoginFlowStateResendCode:
      prefix = @"Custom Resend Code";
      break;
    case AKFLoginFlowStateNone:
    case AKFLoginFlowStateCountryCode:
      return nil;
  }
  return [self _viewWithText:[NSString stringWithFormat:@"%@ %@", prefix, suffix] intrinsicHeight:intrinsicHeight];
}

- (PlaceholderView *)_viewWithText:(NSString *)text intrinsicHeight:(CGFloat)intrinsicHeight
{
  PlaceholderView *view = [[PlaceholderView alloc] initWithFrame:CGRectZero];
  view.intrinsicHeight = intrinsicHeight;
  view.text = text;
  return view;
}

@end
