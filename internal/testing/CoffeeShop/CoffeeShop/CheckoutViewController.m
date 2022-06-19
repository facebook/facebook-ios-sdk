// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "CheckoutViewController.h"

#import "Coffee.h"

#define LABEL_PRICE_TEXT(x)   [NSString stringWithFormat:@"Price: $%.2f", x]
#define LABEL_QTY_TEXT(x)     [NSString stringWithFormat:@"%d", x]

static NSString *const alertTitle = @"Checkout success!";
static NSString *const alertMessage = @"Thank you for your purchase, we hope you enjoy our delicious coffee!";
static NSString *const alertBtn = @"OK!";

@interface CheckoutViewController ()

@property UILabel *labelName;
@property UILabel *labelPrice;
@property UILabel *labelQuantityText;
@property UILabel *labelQuantity;
@property UILabel *labelTotalText;
@property UILabel *labelTotal;

@end

@implementation CheckoutViewController
@synthesize cartProducts = _cartProducts;

- (void)viewDidLoad
{
  [super viewDidLoad];

  const float padding1 = 10;
  const float padding2 = 30;

  self.view.backgroundColor = [UIColor whiteColor];

  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.layer.borderWidth = 0;
  titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  titleLabel.text = @"Order Summary";
  titleLabel.font = [UIFont boldSystemFontOfSize:30];
  titleLabel.textColor = [UIColor grayColor];
  [self.view addSubview:titleLabel];

  _labelName = [self labelWithText:@"Coffee"];
  _labelPrice = [self labelWithText:@"9.99"];
  _labelQuantityText = [self labelWithText:@"Quantity"];
  _labelQuantity = [self labelWithText:@"1"];
  _labelTotalText = [self labelWithText:@"Total"];
  _labelTotal = [self labelWithText:@"9.99"];
  [self updateLabels];

  UITextField *cardTextField = [self textFieldWithText:@"Credit Card"];
  UITextField *addressTextField = [self textFieldWithText:@"Shipping Address"];

  UIButton *confirmBtn = [[UIButton alloc] init];
  confirmBtn.layer.borderWidth = 0;
  confirmBtn.translatesAutoresizingMaskIntoConstraints = NO;
  [confirmBtn setTitle:@"Confirm Order" forState:UIControlStateNormal];
  [confirmBtn setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
  [confirmBtn addTarget:self action:@selector(showSuccess:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:confirmBtn];

  [NSLayoutConstraint activateConstraints:@[
    [titleLabel.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:padding1],
    [titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:padding1],
    [titleLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-1.0 * padding1],

    [_labelName.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:padding1],
    [_labelName.leadingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor constant:padding2],

    [_labelQuantityText.topAnchor constraintEqualToAnchor:_labelName.bottomAnchor constant:padding1],
    [_labelQuantityText.leadingAnchor constraintEqualToAnchor:_labelName.leadingAnchor],

    [_labelTotalText.topAnchor constraintEqualToAnchor:_labelQuantityText.bottomAnchor constant:padding1],
    [_labelTotalText.leadingAnchor constraintEqualToAnchor:_labelQuantityText.leadingAnchor],

    [_labelPrice.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:padding1],
    [_labelPrice.trailingAnchor constraintEqualToAnchor:titleLabel.trailingAnchor],

    [_labelQuantity.topAnchor constraintEqualToAnchor:_labelPrice.bottomAnchor constant:padding1],
    [_labelQuantity.trailingAnchor constraintEqualToAnchor:titleLabel.trailingAnchor],

    [_labelTotal.topAnchor constraintEqualToAnchor:_labelQuantity.bottomAnchor constant:padding1],
    [_labelTotal.trailingAnchor constraintEqualToAnchor:titleLabel.trailingAnchor],

    [cardTextField.topAnchor constraintEqualToAnchor:_labelTotalText.bottomAnchor constant:padding1],
    [cardTextField.leadingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor],
    [cardTextField.trailingAnchor constraintEqualToAnchor:titleLabel.trailingAnchor],

    [addressTextField.topAnchor constraintEqualToAnchor:cardTextField.bottomAnchor constant:padding1],
    [addressTextField.leadingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor],
    [addressTextField.trailingAnchor constraintEqualToAnchor:titleLabel.trailingAnchor],

    [confirmBtn.topAnchor constraintEqualToAnchor:addressTextField.bottomAnchor constant:padding1],
    [confirmBtn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
   ]];
}

- (void)updateLabels
{
  if (!_cartProducts) {
    return;
  }
  Coffee *product = [_cartProducts objectAtIndex:0];
  int quantity = (int)[_cartProducts count];
  float totalPrice = [product price] * quantity;
  [_labelName setText:[product name]];
  [_labelPrice setText:LABEL_PRICE_TEXT([product price])];
  [_labelTotal setText:LABEL_PRICE_TEXT(totalPrice)];
  [_labelQuantity setText:LABEL_QTY_TEXT(quantity)];
}

- (void)showSuccess:(UIButton *)button
{
  UIAlertController *alertView = [UIAlertController alertControllerWithTitle:alertTitle
                                                                     message:alertMessage
                                                              preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *actionDismiss =
  [UIAlertAction actionWithTitle:alertBtn
                           style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction *_Nonnull action) {
                           [[self navigationController] popToRootViewControllerAnimated:YES];
                         }];
  [alertView addAction:actionDismiss];
  [self presentViewController:alertView animated:YES completion:nil];
}

- (UILabel *)labelWithText:(NSString *)text
{
  UILabel *label = [[UILabel alloc] init];
  label.layer.borderWidth = 0;
  label.translatesAutoresizingMaskIntoConstraints = NO;
  label.text = text;
  label.font = [UIFont boldSystemFontOfSize:20];
  label.textColor = [UIColor lightGrayColor];
  [self.view addSubview:label];
  return label;
}

- (UITextField *)textFieldWithText:(NSString *)text
{
  UITextField *textField = [[UITextField alloc] init];
  textField.layer.borderColor = [UIColor lightGrayColor].CGColor;
  textField.layer.borderWidth = 1;
  textField.translatesAutoresizingMaskIntoConstraints = NO;
  textField.placeholder = text;
  textField.font = [UIFont boldSystemFontOfSize:18];
  [self.view addSubview:textField];
  return textField;
}

@end
