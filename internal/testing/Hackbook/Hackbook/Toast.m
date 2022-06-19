// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "Toast.h"

@implementation Toast
{
  UITextView *_textView;
}

#define TOAST_ALPHA 0.9
#define TOAST_CORNER_RADIUS 20.0
#define TOAST_HORIZONTAL_PADDING 20.0
#define TOAST_VERTICAL_PADDING 15.0

#pragma mark - Object Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    _textView = [[UITextView alloc] initWithFrame:CGRectZero];
    _textView.backgroundColor = [UIColor clearColor];
    _textView.editable = NO;
    _textView.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    _textView.opaque = NO;
    _textView.selectable = NO;
    _textView.textColor = [UIColor whiteColor];
    _textView.userInteractionEnabled = YES;
    [self addSubview:_textView];
    self.alpha = TOAST_ALPHA;
    self.backgroundColor = [UIColor darkGrayColor];
    self.layer.cornerRadius = TOAST_CORNER_RADIUS;
    self.opaque = NO;
    self.userInteractionEnabled = YES;
  }
  return self;
}

#pragma mark - Properties

- (NSString *)text
{
  return _textView.text;
}

- (void)setText:(NSString *)text
{
  _textView.text = text;
}

#pragma mark - Layout

- (void)layoutSubviews
{
  [super layoutSubviews];
  _textView.frame = CGRectInset(self.bounds, TOAST_HORIZONTAL_PADDING, TOAST_VERTICAL_PADDING);
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CGSize textConstrainedSize = CGSizeMake(
    size.width - 2 * TOAST_HORIZONTAL_PADDING,
    size.height - 2 * TOAST_VERTICAL_PADDING
  );
  CGSize textSize = [_textView sizeThatFits:textConstrainedSize];
  CGFloat width = MIN(size.width, textSize.width + 2 * TOAST_HORIZONTAL_PADDING);
  CGFloat height = MIN(size.height, textSize.height + 2 * TOAST_VERTICAL_PADDING);
  return CGSizeMake(width, height);
}

@end
