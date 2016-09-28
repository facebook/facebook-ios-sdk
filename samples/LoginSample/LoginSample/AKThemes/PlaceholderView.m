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

#import "PlaceholderView.h"

@implementation PlaceholderView
{
  UILabel *_label;
  CAShapeLayer *_outlineLayer;
}

#pragma mark - Object Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    _label = [[UILabel alloc] initWithFrame:self.bounds];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.textColor = [UIColor whiteColor];
    [self addSubview:_label];

    _outlineLayer = [[CAShapeLayer alloc] init];
    _outlineLayer.backgroundColor = [UIColor clearColor].CGColor;
    _outlineLayer.fillColor = NULL;
    _outlineLayer.lineDashPattern = @[@8.0, @4.0];
    _outlineLayer.lineWidth = 2.0;
    _outlineLayer.opaque = NO;
    _outlineLayer.strokeColor = [UIColor colorWithWhite:204.0/255.0 alpha:1.0].CGColor;
    [self.layer addSublayer:_outlineLayer];

    self.backgroundColor = [UIColor colorWithRed:224.0/255.0 green:39.0/255.0 blue:39.0/255.0 alpha:1.0];
    _intrinsicHeight = 100.0;
  }
  return self;
}

#pragma mark - Properties

- (void)setContentInset:(UIEdgeInsets)contentInset
{
  if (!UIEdgeInsetsEqualToEdgeInsets(_contentInset, contentInset)) {
    _contentInset = contentInset;
    [self setNeedsLayout];
  }
}

- (void)setIntrinsicHeight:(CGFloat)intrinsicHeight
{
  if (_intrinsicHeight != intrinsicHeight) {
    _intrinsicHeight = intrinsicHeight;
    [self invalidateIntrinsicContentSize];
  }
}

- (NSString *)text
{
  return _label.text;
}

- (void)setText:(NSString *)text
{
  NSString *currentText = self.text;
  if ((currentText != text) && ![currentText isEqualToString:text]) {
    _label.text = text;
    [self invalidateIntrinsicContentSize];
  }
}

- (CGSize)intrinsicContentSize
{
  return CGSizeMake(_label.intrinsicContentSize.width, self.intrinsicHeight);
}

#pragma mark - Layout

- (void)layoutSubviews
{
  [super layoutSubviews];

  CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, self.contentInset);

  _label.frame = bounds;

  CGRect outlineFrame = CGRectInset(bounds, 6.0, 6.0);
  if (!CGRectEqualToRect(_outlineLayer.frame, outlineFrame)) {
    _outlineLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(
                                                                            0.0,
                                                                            0.0,
                                                                            CGRectGetWidth(outlineFrame),
                                                                            CGRectGetHeight(outlineFrame))
                                                    cornerRadius:6.0].CGPath;
    _outlineLayer.frame = outlineFrame;
  }
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CGSize textSize = [_label sizeThatFits:size];
  return CGSizeMake(textSize.width, MAX(size.height, self.intrinsicHeight));
}

@end
