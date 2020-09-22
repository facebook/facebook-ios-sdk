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

#import "RPSAutoAppLinkDebugTool.h"

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKUtility.h>

static const int paddingLen = 10;
static const int frameHeight = 30;

@implementation RPSAutoAppLinkDebugTool

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor whiteColor];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
  int frameWidth = scrollView.frame.size.width - paddingLen * 2;

  UILabel *labelName = [[UILabel alloc] initWithFrame:CGRectMake(paddingLen, 50, frameWidth, frameHeight)];
  labelName.font = [UIFont boldSystemFontOfSize:24];
  labelName.textColor = [UIColor grayColor];
  labelName.text = @"Auto Applink Debug Tool";

  UILabel *labelDesc = [[UILabel alloc] initWithFrame:CGRectMake(paddingLen, 100, frameWidth, frameHeight + 10)];
  labelDesc.font = [UIFont systemFontOfSize:14];
  labelDesc.textColor = [UIColor lightGrayColor];
  labelDesc.text = @"Enter your FB App ID and product ID to get your auto applink";
  labelDesc.numberOfLines = 0;

  self.appIDView = [self textFieldWithText:@"FB App ID (ex. 111222333)" keyBoardType:UIKeyboardTypeNumberPad];
  self.appIDView.frame = CGRectMake(paddingLen, 150, frameWidth, frameHeight);

  self.productIDView = [self textFieldWithText:@"Product ID (ex. 123)" keyBoardType:UIKeyboardTypeDefault];
  self.productIDView.frame = CGRectMake(paddingLen, 200, frameWidth, frameHeight);

  UIButton *sendButton = [[UIButton alloc] initWithFrame:CGRectMake(paddingLen, 250, frameWidth, frameHeight + 10)];
  [sendButton setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.4]];
  [sendButton setTitle:@"Send" forState:UIControlStateNormal];
  [sendButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
  [sendButton addTarget:self action:@selector(sendAutoAppLink:) forControlEvents:UIControlEventTouchUpInside];

  [scrollView addSubview:labelName];
  [scrollView addSubview:labelDesc];
  [scrollView addSubview:self.appIDView];
  [scrollView addSubview:self.productIDView];
  [scrollView addSubview:sendButton];
  [self.view addSubview:scrollView];
}

- (UITextField *)textFieldWithText:(NSString *)text
                      keyBoardType:(UIKeyboardType)type
{
  UITextField *textField;
  textField = [[UITextField alloc] init];
  textField.layer.borderColor = [UIColor lightGrayColor].CGColor;
  textField.layer.borderWidth = 1;
  [textField setKeyboardType:type];
  textField.placeholder = text;
  UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
  textField.leftView = paddingView;
  textField.leftViewMode = UITextFieldViewModeAlways;
  return textField;
}

- (void)sendAutoAppLink:(UIButton *)button
{
  NSString *autoAppLink = [NSString stringWithFormat:@"fb%@://applinks?al_applink_data=", self.appIDView.text];
  NSDictionary<NSString *, NSString *> *data = @{@"product_id" : self.productIDView.text,
                                                 @"is_auto_applink" : @"true"};
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
  if (self.appIDView.text.length > 0 && self.productIDView.text.length > 0 && jsonData) {
    NSString *encodeData = [FBSDKUtility URLEncode:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
    NSString *encodeURL = [autoAppLink stringByAppendingString:encodeData];
    NSURL *url = [NSURL URLWithString:encodeURL];
    if (![[UIApplication sharedApplication] openURL:url]) {
      [self showAlert:@"Cannot open the URL!"];
    }
  } else {
    if (self.appIDView.text.length == 0) {
      [self showAlert:@"Invalid App ID!"];
    } else if (self.productIDView.text.length == 0) {
      [self showAlert:@"Invalid Product ID!"];
    } else {
      [self showAlert:@"Cannot generate url from input!"];
    }
  }
}

- (void)showAlert:(NSString *)message
{
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                      message:message
                                                     delegate:self
                                            cancelButtonTitle:@"Close"
                                            otherButtonTitles:nil];
  [alertView show];
}

@end
