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

#import "ReverbProgressDots.h"

static const CGFloat ReverbProgressDotSize = 10.0;

@implementation ReverbProgressDots

#pragma mark - Properties

@synthesize maxProgress = _maxProgress;
@synthesize progress = _progress;
@synthesize progressActiveColor = _progressActiveColor;
@synthesize progressInactiveColor = _progressInactiveColor;

#pragma mark - Layout

- (CGSize)intrinsicContentSize
{
  return CGSizeMake(UIViewNoIntrinsicMetric, ReverbProgressDotSize);
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
  [super drawRect:rect];

  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSaveGState(context);

  NSUInteger maxProgress = self.maxProgress;
  NSUInteger progress = self.progress;
  CGFloat contentWidth = 2 * ReverbProgressDotSize * self.maxProgress - ReverbProgressDotSize;
  CGFloat x = (CGRectGetWidth(self.bounds) - contentWidth) / 2;

  [self.progressActiveColor setFill];
  for (NSUInteger i = 0; i < progress; ++i) {
    CGContextFillEllipseInRect(context, CGRectMake(x, 0.0, ReverbProgressDotSize, ReverbProgressDotSize));
    x += 2 * ReverbProgressDotSize;
  }

  [self.progressInactiveColor setFill];
  for (NSUInteger i = progress; i < maxProgress; ++i) {
    CGContextFillEllipseInRect(context, CGRectMake(x, 0.0, ReverbProgressDotSize, ReverbProgressDotSize));
    x += 2 * ReverbProgressDotSize;
  }

  CGContextRestoreGState(context);
}

@end
