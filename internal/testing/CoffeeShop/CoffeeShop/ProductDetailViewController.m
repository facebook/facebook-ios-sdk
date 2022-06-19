// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "ProductDetailViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "CheckoutViewController.h"
#import "ShoppingCartViewController.h"
#import "TestUtils.h"

#define LABEL_QTY_TEXT(x)   [NSString stringWithFormat:@"Quantity: %d", (int)x]
#define LABEL_PRICE_TEXT(x) [NSString stringWithFormat:@"Price: $%.2f", x]

static NSString *const segueName = @"showCheckout";

// Restrictive Data for testing purpose
NSString *const FBSDKAppEventParameterUserSSN = @"ssn";
NSString *const FBSDKAppEventParameterUserLastName = @"last_name";
NSString *const FBSDKAppEventParameterUserFirstName = @"first name";

@implementation ProductDetailViewController
{
  UILabel *_labelName;
  UILabel *_labelDesc;
  UILabel *_labelPrice;
  UILabel *_labelQuantity;
  UIStepper *_stepper;
}

@synthesize selectedProduct = _selectedProduct;

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor whiteColor];

  _labelName = [[UILabel alloc] init];
  _labelName.font = [UIFont boldSystemFontOfSize:24];
  _labelName.textColor = [UIColor darkGrayColor];
  _labelName.text = _selectedProduct.name;

  _labelDesc = [[UILabel alloc] init];
  _labelDesc.numberOfLines = 0;
  _labelDesc.lineBreakMode = NSLineBreakByWordWrapping;
  _labelDesc.font = [UIFont systemFontOfSize:17];
  _labelDesc.textColor = [UIColor grayColor];
  _labelDesc.text = _selectedProduct.desc;

  _labelPrice = [[UILabel alloc] init];
  _labelPrice.font = [UIFont systemFontOfSize:17];
  _labelPrice.text = LABEL_PRICE_TEXT([_selectedProduct price]);

  _labelQuantity = [[UILabel alloc] init];
  _labelQuantity.font = [UIFont systemFontOfSize:17];

  _stepper = [[UIStepper alloc] init];
  _stepper.value = 1;
  _stepper.minimumValue = 1;
  _stepper.maximumValue = 10;
  _stepper.stepValue = 1;
  [_stepper addTarget:self action:@selector(stepperDidChangeValue:) forControlEvents:UIControlEventValueChanged];

  _labelQuantity.text = LABEL_QTY_TEXT(_stepper.value);

  UIStackView *quantityStack = [[UIStackView alloc] initWithArrangedSubviews:@[_labelQuantity, _stepper]];
  quantityStack.axis = UILayoutConstraintAxisHorizontal;
  quantityStack.distribution = UIStackViewDistributionFill;

  UIButton *addToCartButton = [UIButton buttonWithType:UIButtonTypeSystem];
  addToCartButton.titleLabel.font = [UIFont systemFontOfSize:20];
  [addToCartButton setTitle:@"Add To Shopping Cart" forState:UIControlStateNormal];
  [addToCartButton addTarget:self action:@selector(addToCart:) forControlEvents:UIControlEventTouchUpInside];

  UIButton *moreInfoButton = [UIButton buttonWithType:UIButtonTypeSystem];
  moreInfoButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
  [moreInfoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [moreInfoButton setTitle:@"More Info" forState:UIControlStateNormal];

  UIStackView *fullStack = [[UIStackView alloc] initWithArrangedSubviews:@[_labelName, _labelDesc, _labelPrice, quantityStack, addToCartButton, moreInfoButton]];
  fullStack.translatesAutoresizingMaskIntoConstraints = NO;
  fullStack.axis = UILayoutConstraintAxisVertical;
  fullStack.distribution = UIStackViewDistributionEqualSpacing;
  fullStack.spacing = 10;
  fullStack.alignment = UIStackViewAlignmentFill;
  [self.view addSubview:fullStack];

  for (UIView *v in fullStack.arrangedSubviews) {
    v.translatesAutoresizingMaskIntoConstraints = NO;
  }

  for (UIView *v in quantityStack.arrangedSubviews) {
    v.translatesAutoresizingMaskIntoConstraints = NO;
  }

  [NSLayoutConstraint activateConstraints:@[
    [fullStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:10],
    [fullStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-10],
    [fullStack.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:64 + [UIApplication sharedApplication].statusBarFrame.size.height]
   ]];

  UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"UITree"
                                                                style:UIBarButtonItemStylePlain
                                                               target:[TestUtils class]
                                                               action:@selector(generateUITreeFile)];
  self.navigationItem.rightBarButtonItem = rightItem;
}

#pragma mark - Actions

- (IBAction)addToCart:(id)sender
{
  [self showCheckout];
  NSString *const price = _labelPrice.text;
  NSString *const name = _labelName.text;
  NSString *const quantity = _labelQuantity.text;

  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  if (price) {
    [params setObject:price forKey:@"price"];
  }
  if (name) {
    [params setObject:name forKey:@"product_name"];
  }
  if (quantity) {
    [params setObject:quantity forKey:@"quantity"];
  }
  if (params.allKeys.count > 0) {
    [FBSDKAppEvents.shared logEvent:FBSDKAppEventNameInitiatedCheckout parameters:params];
  } else {
    [FBSDKAppEvents.shared logEvent:FBSDKAppEventNameInitiatedCheckout];
  }

  [ShoppingCartViewController appendItem:_selectedProduct];
  NSDictionary *userData = [_selectedProduct userData];
  [FBSDKAppEvents.shared setUserEmail:userData[@"em"]
                            firstName:userData[@"fn"]
                             lastName:nil
                                phone:nil
                          dateOfBirth:nil
                               gender:nil
                                 city:nil
                                state:nil
                                  zip:nil
                              country:nil];
  [FBSDKAppEvents.shared setUserData:@"apptest@fb.com" forType:FBSDKAppEventEmail];

  NSMutableDictionary *optionalParams = [NSMutableDictionary dictionary];
  [optionalParams setObject:@"custom label 0" forKey:FBSDKAppEventParameterProductCustomLabel0];
  [optionalParams setObject:@"example://product" forKey:FBSDKAppEventParameterProductAppLinkIOSUrl];
  [optionalParams setObject:@"000-00-0000" forKey:FBSDKAppEventParameterUserSSN];
  [optionalParams setObject:@"li" forKey:FBSDKAppEventParameterUserLastName];
  [optionalParams setObject:@"fn" forKey:FBSDKAppEventParameterUserFirstName];
  [optionalParams setObject:@"1 Hacker Way, Menlo Park, CA, 94560" forKey:@"address"];
  [optionalParams setObject:@"YES" forKey:@"prepare for pregnant"];
  [FBSDKAppEvents.shared logEvent:@"manual_initiated_checkout" parameters:optionalParams];
  [FBSDKAppEvents.shared logEvent:@"background_event" parameters:optionalParams];
  [FBSDKAppEvents.shared logEvent:@"deprecated_test" parameters:optionalParams];
  [FBSDKAppEvents.shared logEvent:@"integrity_test" parameters:optionalParams];
  [FBSDKAppEvents.shared logEvent:@"test_event" valueToSum:1 parameters:@{}];
  [FBSDKAppEvents.shared logProductItem:[[NSUUID UUID] UUIDString]
                           availability:FBSDKProductAvailabilityInStock
                              condition:FBSDKProductConditionNew
                            description:name ?: @""
                              imageLink:@"https://www.sample.com"
                                   link:@"https://www.sample.com"
                                  title:name ?: @""
                            priceAmount:[price doubleValue]
                               currency:@"USD"
                                   gtin:@"BLUE MOUNTAIN"
                                    mpn:@"BLUE MOUNTAIN"
                                  brand:@"PHILZ"
                             parameters:optionalParams];
}

- (void)stepperDidChangeValue:(id)sender
{
  _labelQuantity.text = LABEL_QTY_TEXT(_stepper.value);
}

#pragma mark - Navigation

- (void)showCheckout
{
  int quantity = (int)[_stepper value];
  NSMutableArray *products = [NSMutableArray array];
  for (int i = 0; i < quantity; i++) {
    [products addObject:_selectedProduct];
  }
  CheckoutViewController *checkoutVC = [[CheckoutViewController alloc] init];
  [self.navigationController pushViewController:checkoutVC animated:true];
  [checkoutVC setCartProducts:products];
}

@end
