/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RPSAutoAppLinkBasicViewController.h"

static const int paddingLen = 10;

@interface RPSAutoAppLinkBasicViewController ()

@property (nonatomic, strong) Coffee *product;
@property (nonatomic, copy) NSDictionary<NSString *, id> *data;

@end

@implementation RPSAutoAppLinkBasicViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.view.backgroundColor = UIColor.whiteColor;
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
  int stdWidth = scrollView.frame.size.width - paddingLen * 2;

  UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(paddingLen, 50, stdWidth, 30)];
  nameLabel.font = [UIFont boldSystemFontOfSize:24];
  nameLabel.textColor = UIColor.grayColor;

  UILabel *descLabel = [[UILabel alloc] initWithFrame:CGRectMake(paddingLen, 90, stdWidth, 20)];
  descLabel.font = [UIFont systemFontOfSize:14];
  descLabel.textColor = UIColor.lightGrayColor;

  UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(paddingLen, 130, stdWidth, 20)];
  priceLabel.font = [UIFont systemFontOfSize:20];
  priceLabel.textColor = UIColor.blackColor;

  if (self.product == nil) {
    self.product = [[Coffee alloc] initWithName:@"Coffee" desc:@"I am just a coffee" price:1];
  }
  nameLabel.text = self.product.name;
  descLabel.text = [@"Description: " stringByAppendingString:self.product.desc];
  priceLabel.text = [@"Price: $" stringByAppendingString:[@(self.product.price) stringValue]];

  [scrollView addSubview:nameLabel];
  [scrollView addSubview:descLabel];
  [scrollView addSubview:priceLabel];

  if (self.data != nil) {
    UILabel *dataLabel = [[UILabel alloc] init];
    dataLabel.font = [UIFont systemFontOfSize:20];
    dataLabel.textColor = UIColor.blueColor;
    dataLabel.text = [NSString stringWithFormat:@"data is: %@", self.data];
    dataLabel.numberOfLines = 0;
    CGSize size = [dataLabel.text boundingRectWithSize:CGSizeMake(stdWidth, 1000)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName : dataLabel.font}
                                               context:nil].size;
    dataLabel.frame = CGRectMake(paddingLen, 180, size.width, size.height);
    [scrollView addSubview:dataLabel];
  }
  [self.view addSubview:scrollView];
}

@end
