// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "AAMTestViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "TestSuccessViewController.h"
#import "TestUtils.h"
#import "TextInput/AAMTextInputMarco.h"
#import "TextInput/RCTUITextField.h"
#import "TextInput/RCTUITextView.h"

@interface AAMTestViewController ()

@property (nonatomic, strong) UIView *textFieldLoginView;

@end

@implementation AAMTestViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self setTitle:@"Sign Up"];
  self.view.backgroundColor = [UIColor whiteColor];
  [self setupTextFieldLoginView];
  [self.view addSubview:self.textFieldLoginView];
}

- (void)setupTextFieldLoginView
{
  UIScrollView *scrollview = [[UIScrollView alloc] initWithFrame:self.view.frame];
  scrollview.scrollEnabled = YES;
  self.textFieldLoginView = scrollview;

  UILabel *phLabel = [self labelWithText:@"Phone"];
  UITextField *ph = [self textFieldWithText:ADVANCED_MATCHING_PHONE placeholder:@"Phone" PIIType:AutomaticMatchingPhone inputViewType:TextInputUIKit];
  UITextField *em = [self textFieldWithText:ADVANCED_MATCHING_EMAIL placeholder:@"Email" PIIType:AutomaticMatchingEmail inputViewType:TextInputUIKit];
  UITextField *fn = [self textFieldWithText:ADVANCED_MATCHING_FIRST_NAME placeholder:@"First Name" PIIType:AutomaticMatchingFirstName inputViewType:TextInputUIKit];
  UITextField *ln = [self textFieldWithText:ADVANCED_MATCHING_LAST_NAME placeholder:@"Last Name" PIIType:AutomaticMatchingLastName inputViewType:TextInputUIKit];
  UITextField *addr = [self textFieldWithText:@"" placeholder:@"Address" PIIType:AutomaticMatchingAddress inputViewType:TextInputUIKit];
  UITextField *zip = [self textFieldWithText:ADVANCED_MATCHING_ZIP placeholder:@"Zip Code" PIIType:AutomaticMatchingAddress inputViewType:TextInputUIKit];
  UITextField *cn = [self textFieldWithText:@"" placeholder:@"Country" PIIType:AutomaticMatchingAddress inputViewType:TextInputUIKit];
  UITextField *st = [self textFieldWithText:ADVANCED_MATCHING_STATE placeholder:@"State" PIIType:AutomaticMatchingAddress inputViewType:TextInputUIKit];
  UITextField *city = [self textFieldWithText:ADVANCED_MATCHING_CITY placeholder:@"City" PIIType:AutomaticMatchingAddress inputViewType:TextInputUIKit];
  UITextField *pwd = [self textFieldWithText:ADVANCED_MATCHING_PWD placeholder:@"Password" PIIType:AutomaticMatchingPassword inputViewType:TextInputUIKit];
  UITextField *rct = [self textFieldWithText:ADVANCED_MATCHING_PWD placeholder:@"RCTPassword(optional)" PIIType:AutomaticMatchingPassword inputViewType:TextInputRCT];
  UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
  btn.layer.borderWidth = 1;
  btn.translatesAutoresizingMaskIntoConstraints = NO;
  [btn setTitle:@"register" forState:UIControlStateNormal];
  [btn setTintColor:UIColor.blackColor];
  [btn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
  [btn addTarget:self action:@selector(onClickRegister) forControlEvents:UIControlEventTouchUpInside];
  NSDictionary<NSString *, id> *views = NSDictionaryOfVariableBindings(phLabel, ph, em, fn, ln, addr, zip, cn, st, city, pwd, rct, btn);

  [self addSubviews:views toView:scrollview];
  [self setConstraintsForSubViews:views toView:scrollview];

  [self.textFieldLoginView didMoveToWindow];
  for (UIView *subview in self.textFieldLoginView.subviews) {
    [subview didMoveToWindow];
  }
}

- (void)onClickRegister
{
  [FBSDKAppEvents.shared logEvent:@"e2e_test_automatic_advanced_matching"];
  [FBSDKAppEvents.shared flush];

  [TestUtils performBlock:^() {
               NSArray<NSDictionary<NSString *, NSString *> *> *userDataArrays = [TestUtils getUserData];
               for (NSDictionary<NSString *, NSString *> *userData in userDataArrays) {
                 if ([userData[@"r1"] isEqualToString:[FBSDKUtility SHA256Hash:[self normalizeValue:ADVANCED_MATCHING_EMAIL]]]
                     && [userData[@"r2"] containsString:[FBSDKUtility SHA256Hash:[self normalizeValue:ADVANCED_MATCHING_PHONE]]]
                     && [userData[@"r4"] isEqualToString:[FBSDKUtility SHA256Hash:[self normalizeValue:ADVANCED_MATCHING_CITY]]]
                     && [userData[@"r5"] isEqualToString:[FBSDKUtility SHA256Hash:[self normalizeValue:ADVANCED_MATCHING_STATE]]]
                     && [userData[@"r6"] isEqualToString:[FBSDKUtility SHA256Hash:[self normalizeValue:ADVANCED_MATCHING_ZIP]]]
                     && [userData[@"r7"] isEqualToString:[FBSDKUtility SHA256Hash:[self normalizeValue:ADVANCED_MATCHING_FIRST_NAME]]]
                     && [userData[@"r8"] isEqualToString:[FBSDKUtility SHA256Hash:[self normalizeValue:ADVANCED_MATCHING_LAST_NAME]]]) {
                   TestSuccessViewController *vc = [[TestSuccessViewController alloc] init];
                   [self.navigationController pushViewController:vc animated:YES];
                   return;
                 }
               }
               [TestUtils showAlert:@"Fail to set automatic advanced matching"];
             }
               afterDelay:4];
}

- (void)addSubviews:(NSDictionary<NSString *, id> *)subviews toView:(UIView *)view
{
  for (NSString *key in subviews) {
    UIView *subview = (UIView *)subviews[key];
    [view addSubview:subview];
  }
}

- (void)setConstraintsForSubViews:(NSDictionary<NSString *, id> *)views toView:(UIView *)view
{
  for (NSString *key in views) {
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-20-[%@(width)]-20-|", key]
                                                                 options:0
                                                                 metrics:@{@"width" : @((self.textFieldLoginView.frame.size.width - 40))}
                                                                   views:views]];
  }
  [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[phLabel(==30)]-10-[ph(==30)]-10-[em(==ph)]-10-[fn(==ph)]-10-[ln(==ph)]-10-[addr(==ph)]-10-[zip(==ph)]-10-[cn(==ph)]-10-[st(==ph)]-10-[city(==ph)]-10-[pwd(==ph)]-10-[rct(==ph)]-10-[btn(==ph)]|"
                                                               options:0
                                                               metrics:nil
                                                                 views:views]];
}

- (UILabel *)labelWithText:(NSString *)text
{
  UILabel *label = [[UILabel alloc] init];
  label.layer.borderWidth = 0;
  label.translatesAutoresizingMaskIntoConstraints = NO;
  label.text = text;
  return label;
}

- (UITextField *)textFieldWithText:(NSString *)text
                       placeholder:(NSString *)placeholder
                           PIIType:(AutomaticMatchingPIIType)piiType
                     inputViewType:(TextInputType)inputType
{
  UITextField *textField;
  if (inputType == TextInputRCT) {
    textField = [[RCTUITextField alloc] init];
  } else {
    textField = [[UITextField alloc] init];
  }

  textField.layer.borderColor = [UIColor lightGrayColor].CGColor;
  textField.layer.borderWidth = 1;
  textField.translatesAutoresizingMaskIntoConstraints = NO;
  textField.text = text;
  textField.placeholder = placeholder;
  UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
  textField.leftView = paddingView;
  textField.leftViewMode = UITextFieldViewModeAlways;
  switch ((int)piiType) {
    case AutomaticMatchingPhone:
      [textField setKeyboardType:UIKeyboardTypePhonePad];
      break;
    case AutomaticMatchingEmail:
      [textField setKeyboardType:UIKeyboardTypeEmailAddress];
      break;
    case AutomaticMatchingPassword:
      [textField setSecureTextEntry:YES];
      break;
    default:
      break;
  }
  return textField;
}

- (NSString *)normalizeValue:(NSString *)value
{
  if (value.length == 0) {
    return @"";
  }
  return [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].lowercaseString;
}

@end
