// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "SuggestedEventsTestViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "TestSuccessViewController.h"
#import "TestUtils.h"

static const int paddingLen = 40;

@interface SuggestedEventsTestViewController ()
{
  NSArray *_pickerData;
}
@end

@implementation SuggestedEventsTestViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.title = @"SuggestedEventsTestVC";
  self.view.backgroundColor = [UIColor whiteColor];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
  int stdWidth = scrollView.frame.size.width - paddingLen * 2;

  UILabel *registerLabel = [[UILabel alloc] initWithFrame:CGRectMake(paddingLen, 50, stdWidth, 30)];
  registerLabel.textAlignment = NSTextAlignmentCenter;
  registerLabel.font = [UIFont boldSystemFontOfSize:24];
  registerLabel.textColor = [UIColor grayColor];
  registerLabel.text = @"Register";

  UILabel *userNameLabel = [self labelWithText:@"USERNAME" frame:CGRectMake(paddingLen, 100, stdWidth, 20)];
  UITextField *userTextField = [self textFieldWithFrame:CGRectMake(paddingLen, 130, stdWidth, 20)];

  UILabel *fullNameLabel = [self labelWithText:@"FULL NAME" frame:CGRectMake(paddingLen, 160, stdWidth, 20)];
  UITextField *fullNameTextField = [self textFieldWithFrame:CGRectMake(paddingLen, 190, stdWidth, 20)];

  UILabel *emailLabel = [self labelWithText:@"EMAIL ADDRESS" frame:CGRectMake(paddingLen, 220, stdWidth, 20)];
  UITextField *emailTextField = [self textFieldWithFrame:CGRectMake(paddingLen, 250, stdWidth, 20)];

  UILabel *pwdLabel = [self labelWithText:@"PASSWORD" frame:CGRectMake(paddingLen, 280, stdWidth, 20)];
  UITextField *pwdTextField = [self textFieldWithFrame:CGRectMake(paddingLen, 310, stdWidth, 20)];

  UIButton *submitBtn = [[UIButton alloc] initWithFrame:CGRectMake(paddingLen, 360, stdWidth, 40)];
  [submitBtn setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.4]];
  [submitBtn setTitle:@"Sign Up" forState:UIControlStateNormal];
  [submitBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
  [submitBtn addTarget:self action:@selector(onClickSignUp) forControlEvents:UIControlEventTouchUpInside];

  UIButton *addToCartBtn = [[UIButton alloc] initWithFrame:CGRectMake(paddingLen, 410, stdWidth, 40)];
  [addToCartBtn setBackgroundColor:[[UIColor grayColor] colorWithAlphaComponent:0.2]];
  [addToCartBtn setTitle:@"Add To Cart" forState:UIControlStateNormal];
  [addToCartBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
  [addToCartBtn addTarget:self action:@selector(onClickAddToCart) forControlEvents:UIControlEventTouchUpInside];

  [scrollView addSubview:registerLabel];
  [scrollView addSubview:userNameLabel];
  [scrollView addSubview:userTextField];
  [scrollView addSubview:fullNameLabel];
  [scrollView addSubview:fullNameTextField];
  [scrollView addSubview:emailLabel];
  [scrollView addSubview:emailTextField];
  [scrollView addSubview:pwdLabel];
  [scrollView addSubview:pwdTextField];
  [scrollView addSubview:submitBtn];
  [scrollView addSubview:addToCartBtn];
  [self.view addSubview:scrollView];
}

- (UILabel *)labelWithText:(NSString *)text
                     frame:(CGRect)frame
{
  UILabel *label = [[UILabel alloc] initWithFrame:frame];
  label.font = [UIFont systemFontOfSize:16];
  label.textColor = [UIColor lightGrayColor];
  label.text = text;
  return label;
}

- (UITextField *)textFieldWithFrame:(CGRect)frame
{
  UITextField *textField = [[UITextField alloc] initWithFrame:frame];
  CALayer *border = [CALayer layer];
  CGFloat borderWidth = 1;
  border.borderColor = [UIColor darkGrayColor].CGColor;
  border.frame = CGRectMake(0, textField.frame.size.height - borderWidth, textField.frame.size.width, textField.frame.size.height);
  border.borderWidth = borderWidth;
  [textField.layer addSublayer:border];
  textField.layer.masksToBounds = YES;
  return textField;
}

- (void)onClickSignUp
{
  [TestUtils performBlock:^() {
               TestSuccessViewController *vc = [[TestSuccessViewController alloc] init];
               [self.navigationController pushViewController:vc animated:YES];
             }
               afterDelay:4];
}

- (void)onClickAddToCart
{
  [TestUtils performBlock:^() {
               NSArray<NSDictionary *> *events = [TestUtils getEvents];
               for (NSDictionary *event in events) {
                 NSString *eventName = event[EVENT_NAME_KEY];
                 if ([eventName isEqualToString:@"fb_mobile_add_to_cart"] && event[@"_is_suggested_event"] != nil) {
                   TestSuccessViewController *vc = [[TestSuccessViewController alloc] init];
                   [self.navigationController pushViewController:vc animated:YES];
                   return;
                 }
               }
               [TestUtils showAlert:@"Fail to send back suggested event"];
             }
               afterDelay:4];
}

@end
