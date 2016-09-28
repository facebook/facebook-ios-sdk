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

#import "ReverbProgressBar.h"

static const CGFloat ReverbProgressBarCornerRadius = 3.0;

@implementation ReverbProgressBar

#pragma mark - Properties

@synthesize maxProgress = _maxProgress;
@synthesize progress = _progress;
@synthesize progressActiveColor = _progressActiveColor;
@synthesize progressInactiveColor = _progressInactiveColor;

#pragma mark - Layout

- (CGSize)intrinsicContentSize
{
  return CGSizeMake(UIViewNoIntrinsicMetric, 10.0);
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
  [super drawRect:rect];

  CGContextRef context = UIGraphicsGetCurrentContext();
  CGRect bounds = self.bounds;
  CGMutablePathRef path;

  NSUInteger maxProgress = self.maxProgress;
  NSUInteger progress = self.progress;

  if ((progress > 0) && (progress < maxProgress)) {
    CGContextSaveGState(context);
    path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, CGRectGetMinX(bounds) + ReverbProgressBarCornerRadius, CGRectGetMinY(bounds));
    [self _addPointsForCenterDivideToPath:path rightIsOutside:YES];
    [self _addPointsForLeftCornersToPath:path];
    CGPathCloseSubpath(path);
    [self.progressActiveColor setFill];
    CGContextAddPath(context, path);
    CGPathRelease(path);
    CGContextFillPath(context);
    CGContextRestoreGState(context);

    CGContextSaveGState(context);
    path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, CGRectGetMaxX(bounds) - ReverbProgressBarCornerRadius, CGRectGetMinY(bounds));
    [self _addPointsForRightCornersToPath:path];
    [self _addPointsForCenterDivideToPath:path rightIsOutside:NO];
    CGPathCloseSubpath(path);
    [self.progressInactiveColor setFill];
    CGContextAddPath(context, path);
    CGPathRelease(path);
    CGContextFillPath(context);
    CGContextRestoreGState(context);
  } else {
    CGContextSaveGState(context);
    path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, CGRectGetMinX(bounds) + ReverbProgressBarCornerRadius, CGRectGetMinY(bounds));
    [self _addPointsForRightCornersToPath:path];
    [self _addPointsForLeftCornersToPath:path];
    CGPathCloseSubpath(path);
    if (progress <= 0) {
      [self.progressInactiveColor setFill];
    } else {
      [self.progressActiveColor setFill];
    }
    CGContextAddPath(context, path);
    CGPathRelease(path);
    CGContextFillPath(context);
    CGContextRestoreGState(context);
  }
}

- (void)_addPointsForCenterDivideToPath:(CGMutablePathRef)path rightIsOutside:(BOOL)rightIsOutside
{
  NSUInteger maxProgress = self.maxProgress;
  if (maxProgress == 0.0) {
    // no divide by zero
    return;
  }

  CGRect bounds = self.bounds;
  NSUInteger progress = self.progress;
  CGFloat progressX = CGRectGetMinX(bounds) + (CGRectGetWidth(bounds) * progress / maxProgress);

  CGPoint points[] = {
    CGPointMake(progressX - ReverbProgressBarCornerRadius, CGRectGetMinY(bounds)),
    CGPointMake(progressX, CGRectGetMidY(bounds)),
    CGPointMake(progressX - ReverbProgressBarCornerRadius, CGRectGetMaxY(bounds)),
  };

  NSUInteger pointCount = sizeof(points) / sizeof(points[0]);
  if (rightIsOutside) {
    for (NSUInteger i = 0; i < pointCount; ++i) {
      CGPathAddLineToPoint(path, NULL, points[i].x, points[i].y);
    }
  } else {
    for (NSUInteger i = pointCount; i > 0; i--) {
      CGPathAddLineToPoint(path, NULL, points[i - 1].x, points[i - 1].y);
    }
  }
}

- (void)_addPointsForLeftCornersToPath:(CGMutablePathRef)path
{
  CGRect bounds = self.bounds;
  CGPathAddLineToPoint(path, NULL, CGRectGetMinX(bounds) + ReverbProgressBarCornerRadius, CGRectGetMaxY(bounds));
  CGPathAddArcToPoint(path,
                      NULL,
                      CGRectGetMinX(bounds),
                      CGRectGetMaxY(bounds),
                      CGRectGetMinX(bounds),
                      CGRectGetMaxY(bounds) - ReverbProgressBarCornerRadius,
                      ReverbProgressBarCornerRadius);
  CGPathAddLineToPoint(path, NULL, CGRectGetMinX(bounds), CGRectGetMinY(bounds) + ReverbProgressBarCornerRadius);
  CGPathAddArcToPoint(path,
                      NULL,
                      CGRectGetMinX(bounds),
                      CGRectGetMinY(bounds),
                      CGRectGetMinX(bounds) + ReverbProgressBarCornerRadius,
                      CGRectGetMinY(bounds),
                      ReverbProgressBarCornerRadius);
}

- (void)_addPointsForRightCornersToPath:(CGMutablePathRef)path
{
  CGRect bounds = self.bounds;
  CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(bounds) - ReverbProgressBarCornerRadius, CGRectGetMinY(bounds));
  CGPathAddArcToPoint(path,
                      NULL,
                      CGRectGetMaxX(bounds),
                      CGRectGetMinY(bounds),
                      CGRectGetMaxX(bounds),
                      CGRectGetMinY(bounds) + ReverbProgressBarCornerRadius,
                      ReverbProgressBarCornerRadius);
  CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds) - ReverbProgressBarCornerRadius);
  CGPathAddArcToPoint(path,
                      NULL,
                      CGRectGetMaxX(bounds),
                      CGRectGetMaxY(bounds),
                      CGRectGetMaxX(bounds) - ReverbProgressBarCornerRadius,
                      CGRectGetMaxY(bounds),
                      ReverbProgressBarCornerRadius);
}

@end
