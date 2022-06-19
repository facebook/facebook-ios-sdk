// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

#import "Coffee.h"

@interface CheckoutViewController : UIViewController

@property (nonatomic, copy) NSArray *cartProducts;

- (void)updateLabels;

@end
