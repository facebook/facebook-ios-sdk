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

#import "ToastView.h"

@implementation ToastView
{
  UITextView *_textView;
}

#define TOAST_ALPHA 0.9
#define TOAST_ANIMATION_DURATION 0.3
#define TOAST_CORNER_RADIUS 20.0
#define TOAST_HORIZONTAL_PADDING 20.0
#define TOAST_MARGIN 20.0
#define TOAST_VERTICAL_PADDING 15.0

#pragma mark - Class Metods

+ (instancetype)showInWindow:(UIWindow *)window text:(NSString *)text duration:(NSTimeInterval)duration
{
  ToastView *toast = [[self alloc] initWithFrame:CGRectZero];
  toast.text = text;
  [toast showInWindow:window duration:duration];
  return toast;
}

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
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapHandler:)]];
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

#pragma mark - Public Methods

- (void)dismiss
{
  if (!self.superview) {
    return;
  }
  [UIView animateWithDuration:TOAST_ANIMATION_DURATION animations:^{
    self.alpha = 0.0;
  } completion:^(BOOL finishedHiding) {
    [self removeFromSuperview];
  }];
}

- (void)showInWindow:(UIWindow *)window duration:(NSTimeInterval)duration
{
  CGRect windowBounds = CGRectInset(window.bounds, TOAST_MARGIN, TOAST_MARGIN);
  CGRect toastBounds = CGRectZero;
  toastBounds.size = [self sizeThatFits:windowBounds.size];
  self.bounds = toastBounds;
  self.center = CGPointMake(CGRectGetMidX(windowBounds), CGRectGetMidY(windowBounds));
  CGFloat alpha = self.alpha;
  self.alpha = 0.0;
  [window addSubview:self];
  [UIView animateWithDuration:TOAST_ANIMATION_DURATION animations:^{
    self.alpha = alpha;
  } completion:^(BOOL finishedShowing) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [self dismiss];
    });
  }];
}

#pragma mark - Layout

- (void)layoutSubviews
{
  [super layoutSubviews];
  _textView.frame = CGRectInset(self.bounds, TOAST_HORIZONTAL_PADDING, TOAST_VERTICAL_PADDING);
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CGSize textConstrainedSize = CGSizeMake(size.width - 2 * TOAST_HORIZONTAL_PADDING,
                                          size.height - 2 * TOAST_VERTICAL_PADDING);
  CGSize textSize = [_textView sizeThatFits:textConstrainedSize];
  CGFloat width = MIN(size.width, textSize.width + 2 * TOAST_HORIZONTAL_PADDING);
  CGFloat height = MIN(size.height, textSize.height + 2 * TOAST_VERTICAL_PADDING);
  return CGSizeMake(width, height);
}

#pragma mark - Helper Methods

- (void)_tapHandler:(UITapGestureRecognizer *)tapGestureRecognizer
{
  [self dismiss];
}

@end
