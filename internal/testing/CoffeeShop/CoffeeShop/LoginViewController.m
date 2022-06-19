// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "LoginViewController.h"

#import "TextInput/AAMTextInputMarco.h"
#import "TextInput/RCTUITextField.h"
#import "TextInput/RCTUITextView.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self setTitle:@"Login"];
  self.view.backgroundColor = [UIColor whiteColor];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"SwitchView"
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(switchView)];

  [self setupTextFieldLoginView];
  [self setupTextViewLoginView];
  self.isSelectTextFieldLoginView = YES;
  [self.view addSubview:self.textFieldLoginView];
}

- (void)setupTextFieldLoginView
{
  UIScrollView *scrollview = [[UIScrollView alloc] initWithFrame:self.view.frame];
  scrollview.scrollEnabled = YES;
  self.textFieldLoginView = scrollview;

  UILabel *phLabel = [self labelWithText:@"Phone"];
  UITextField *ph = [self textFieldWithText:@"Phone" PIIType:AutomaticMatchingPhone InputViewType:TextInputUIKit];
  UILabel *emLabel = [self labelWithText:@"Incorret Label"];
  UITextField *em = [self textFieldWithText:@"Email" PIIType:AutomaticMatchingEmail InputViewType:TextInputUIKit];
  UITextField *name = [self textFieldWithText:@"Full name" PIIType:AutomaticMatchingFullName InputViewType:TextInputUIKit];
  UITextField *ln = [self textFieldWithText:@"Last name" PIIType:AutomaticMatchingLastName InputViewType:TextInputUIKit];
  UITextField *fn = [self textFieldWithText:@"First name" PIIType:AutomaticMatchingFirstName InputViewType:TextInputUIKit];
  UITextField *addr = [self textFieldWithText:@"Address" PIIType:AutomaticMatchingAddress InputViewType:TextInputUIKit];
  UITextField *zip = [self textFieldWithText:@"Zip Code" PIIType:AutomaticMatchingAddress InputViewType:TextInputUIKit];
  UITextField *ct = [self textFieldWithText:@"Country" PIIType:AutomaticMatchingAddress InputViewType:TextInputUIKit];
  UITextField *st = [self textFieldWithText:@"State" PIIType:AutomaticMatchingAddress InputViewType:TextInputUIKit];
  UITextField *city = [self textFieldWithText:@"City" PIIType:AutomaticMatchingAddress InputViewType:TextInputUIKit];
  UITextField *pwd = [self textFieldWithText:@"Password(optional)" PIIType:AutomaticMatchingPassword InputViewType:TextInputUIKit];
  UITextField *rct = [self textFieldWithText:@"RCTPassword(optional)" PIIType:AutomaticMatchingPassword InputViewType:TextInputRCT];
  UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
  btn.layer.borderWidth = 1;
  btn.translatesAutoresizingMaskIntoConstraints = NO;
  [btn setTitle:@"register" forState:UIControlStateNormal];
  [btn setTintColor:UIColor.blackColor];
  [btn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
  NSDictionary<NSString *, id> *views = NSDictionaryOfVariableBindings(phLabel, ph, emLabel, em, name, ln, fn, addr, zip, ct, st, city, pwd, rct, btn);

  [self addSubviews:views toView:scrollview];
  [self setConstraintsForSubViews:views toView:scrollview];
}

- (void)setupTextViewLoginView
{
  UIScrollView *scrollview = [[UIScrollView alloc] initWithFrame:self.view.frame];
  scrollview.scrollEnabled = YES;
  self.textViewLoginView = scrollview;

  UILabel *phLabel = [self labelWithText:@"Incorret Label"];
  UITextView *ph = [self textViewWithText:@"(TextView)Phone" PIIType:AutomaticMatchingPhone InputViewType:TextInputUIKit];
  UILabel *emLabel = [self labelWithText:@"Email"];
  UITextView *em = [self textViewWithText:@"(TextView)Email" PIIType:AutomaticMatchingEmail InputViewType:TextInputUIKit];
  UITextView *name = [self textViewWithText:@"(TextView)Full name" PIIType:AutomaticMatchingFullName InputViewType:TextInputUIKit];
  UITextView *ln = [self textViewWithText:@"(TextView)Last name" PIIType:AutomaticMatchingLastName InputViewType:TextInputUIKit];
  UITextView *fn = [self textViewWithText:@"(TextView)First name" PIIType:AutomaticMatchingFirstName InputViewType:TextInputUIKit];
  UITextView *addr = [self textViewWithText:@"(TextView)Address" PIIType:AutomaticMatchingAddress InputViewType:TextInputUIKit];
  UITextView *zip = [self textViewWithText:@"(TextView)Zip Code" PIIType:AutomaticMatchingAddress InputViewType:TextInputUIKit];
  UITextView *ct = [self textViewWithText:@"(TextView)Country" PIIType:AutomaticMatchingAddress InputViewType:TextInputUIKit];
  UITextView *st = [self textViewWithText:@"(TextView)State" PIIType:AutomaticMatchingAddress InputViewType:TextInputUIKit];
  UITextView *city = [self textViewWithText:@"(TextView)City" PIIType:AutomaticMatchingAddress InputViewType:TextInputUIKit];
  UITextView *pwd = [self textViewWithText:@"(TextView)Password(optional)" PIIType:AutomaticMatchingPassword InputViewType:TextInputUIKit];
  UITextView *rct = [self textViewWithText:@"(RCTUITextView)Password(optional)" PIIType:AutomaticMatchingPassword InputViewType:TextInputRCT];
  UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
  btn.layer.borderWidth = 1;
  btn.translatesAutoresizingMaskIntoConstraints = NO;
  [btn setTitle:@"register" forState:UIControlStateNormal];
  [btn setTintColor:UIColor.blackColor];
  [btn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
  NSDictionary<NSString *, id> *views = NSDictionaryOfVariableBindings(phLabel, ph, emLabel, em, name, ln, fn, addr, zip, ct, st, city, pwd, rct, btn);

  [self addSubviews:views toView:scrollview];
  [self setConstraintsForSubViews:views toView:scrollview];
}

- (void)switchView
{
  if (self.isSelectTextFieldLoginView) {
    [self.textFieldLoginView removeFromSuperview];
    [self.view addSubview:self.textViewLoginView];
  } else {
    [self.textViewLoginView removeFromSuperview];
    [self.view addSubview:self.textFieldLoginView];
  }

  self.isSelectTextFieldLoginView = !self.isSelectTextFieldLoginView;
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
  [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-40-[phLabel(==32)]-10-[ph(==44)]-10-[emLabel(==32)]-10-[em(==ph)]-20-[name(==ph)]-20-[ln(==ph)]-20-[fn(==ph)]-20-[addr(==ph)]-20-[zip(==ph)]-20-[ct(==ph)]-20-[st(==ph)]-20-[city(==ph)]-20-[pwd(==ph)]-20-[rct(==ph)]-20-[btn(==ph)]|"
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
                           PIIType:(AutomaticMatchingPIIType)piiType
                     InputViewType:(TextInputType)inputType
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
  textField.placeholder = text;
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

- (UITextView *)textViewWithText:(NSString *)text
                         PIIType:(AutomaticMatchingPIIType)piiType
                   InputViewType:(TextInputType)inputType
{
  UITextView *textView;
  if (inputType == TextInputRCT) {
    RCTUITextView *_view = [[RCTUITextView alloc] init];
    _view.placeholder = text;
    textView = _view;
  } else {
    textView = [[UITextView alloc] init];
    [textView setText:text];
  }

  textView.layer.borderColor = [UIColor lightGrayColor].CGColor;
  textView.layer.borderWidth = 1;
  textView.translatesAutoresizingMaskIntoConstraints = NO;
  switch ((int)piiType) {
    case AutomaticMatchingPhone:
      [textView setKeyboardType:UIKeyboardTypePhonePad];
      break;
    case AutomaticMatchingEmail:
      [textView setKeyboardType:UIKeyboardTypeEmailAddress];
      break;
    case AutomaticMatchingPassword:
      [textView setSecureTextEntry:YES];
      break;
    default:
      break;
  }
  return textView;
}

@end
