// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "RCTUITextField.h"

@implementation RCTUITextField

#pragma mark - Properties

- (void)setPlaceholder:(NSString *)placeholder
{
  [super setPlaceholder:placeholder];
  self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeholder attributes:nil];
}

#pragma mark - Overrides

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange notifyDelegate:(BOOL)notifyDelegate
{
  [super setSelectedTextRange:selectedTextRange];
}

- (void)paste:(id)sender
{
  [super paste:sender];
}

@end
