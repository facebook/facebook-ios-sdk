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

#import "ManualLoggingViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "AlertControllerUtility.h"

@interface ManualLoggingViewController ()

@property (weak, nonatomic) IBOutlet UITextField *purchasePriceField;
@property (weak, nonatomic) IBOutlet UITextField *purchaseCurrencyField;
@property (weak, nonatomic) IBOutlet UITextField *itemPriceField;
@property (weak, nonatomic) IBOutlet UITextField *itemCurrencyField;

@end

@implementation ManualLoggingViewController

#pragma mark - Log Purchase Event

- (IBAction)logPurchase:(id)sender
{
  UIAlertController *alertController;
  if (![self _validInputPrice:_purchasePriceField]) {
    alertController = [AlertControllerUtility alertControllerWithTitle:@"Invalid purchase price" message:@"Purchase price must be a number."];
    [self presentViewController:alertController animated:YES completion:nil];
    return;
  }
  if (![self _validInput:_purchaseCurrencyField]) {
    alertController = [AlertControllerUtility alertControllerWithTitle:@"Invalid currency" message:@"Currency cannot be empty."];
    [self presentViewController:alertController animated:YES completion:nil];
    return;
  }
  [FBSDKAppEvents logPurchase:[_purchasePriceField.text doubleValue]
                     currency:_purchaseCurrencyField.text];
  // View your event at https://developers.facebook.com/analytics/<APP_ID>. See https://developers.facebook.com/docs/analytics for details.
  alertController = [AlertControllerUtility alertControllerWithTitle:@"Log Event" message:@"Log Event Success"];
  [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Log Add To Cart Event

- (IBAction)logAddToCart:(id)sender
{
  UIAlertController *alertController;
  if (![self _validInputPrice:_itemPriceField]) {
    alertController = [AlertControllerUtility alertControllerWithTitle:@"Invalid item price" message:@"Item price must be a number."];
    [self presentViewController:alertController animated:YES completion:nil];
    return;
  }
  if (![self _validInput:_itemCurrencyField]) {
    alertController = [AlertControllerUtility alertControllerWithTitle:@"Invalid currency" message:@"Currency cannot be empty."];
    [self presentViewController:alertController animated:YES completion:nil];
    return;
  }
  // See https://developers.facebook.com/docs/app-events/ios#events for predefined events.
  [FBSDKAppEvents logEvent:FBSDKAppEventNameAddedToCart
                valueToSum:[_itemPriceField.text doubleValue]
                parameters:@{ FBSDKAppEventParameterNameCurrency : _itemCurrencyField.text }];
  // View your event at https://developers.facebook.com/analytics/<APP_ID>. See https://developers.facebook.com/docs/analytics for details.
  alertController = [AlertControllerUtility alertControllerWithTitle:@"Log Event" message:@"Log Event Success"];
  [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Helper Method

- (BOOL)_validInput:(UITextField *)input
{
  return input.text.length > 0;
}

- (BOOL)_validInputPrice:(UITextField *)input
{
  NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
  if (input.text.length == 0 || ![formatter numberFromString:input.text]) {
    return NO;
  }
  return YES;
}
@end
