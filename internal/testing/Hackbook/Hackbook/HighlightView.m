// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "HighlightView.h"

@implementation HighlightView

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
  }
  return self;
}

- (void)drawRect:(CGRect)rect
{
  CGContextRef context = UIGraphicsGetCurrentContext();
  [[UIColor colorWithRed:59.0 / 255.0 green:89.0 / 255.0 blue:152.0 / 255 / 0 alpha:1.0] setStroke];
  const CGFloat lineWidth = 2.0;
  CGContextSetLineWidth(context, lineWidth);
  CGContextStrokeEllipseInRect(context, CGRectInset(self.bounds, lineWidth, lineWidth));
}

@end
