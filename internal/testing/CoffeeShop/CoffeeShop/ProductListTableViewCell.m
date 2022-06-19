// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "ProductListTableViewCell.h"

@implementation ProductListTableViewCell

@synthesize labelName = _labelName;
@synthesize labelPrice = _labelPrice;

- (void)awakeFromNib
{
  [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  [super setSelected:selected animated:animated];
}

@end
