/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RPSAutoAppLinkStoryboardViewController.h"

@interface RPSAutoAppLinkStoryboardViewController ()

@property (nonatomic, strong) Coffee *product;
@property (nonatomic, copy) NSDictionary<NSString *, id> *data;

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *descLabel;
@property (nonatomic, weak) IBOutlet UILabel *priceLabel;
@property (nonatomic, weak) IBOutlet UILabel *dataLabel;

@end

@implementation RPSAutoAppLinkStoryboardViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  if (self.product == nil) {
    self.product = [[Coffee alloc] initWithName:@"Coffee" desc:@"I am just a STORYBOARD coffee" price:1];
  }

  self.nameLabel.text = self.product.name;
  self.descLabel.text = [@"Description: " stringByAppendingString:self.product.desc];
  self.priceLabel.text = [@"Price: $" stringByAppendingString:[@(self.product.price) stringValue]];

  if (self.data != nil) {
    self.dataLabel.text = [NSString stringWithFormat:@"data is: %@", self.data];
  }
}

@end
