/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKMessengerIcon.h"

@implementation FBSDKMessengerIcon

- (CGPathRef)pathWithSize:(CGSize)size
{
  CGAffineTransform transformValue = CGAffineTransformMakeScale(size.width / 61.0, size.height / 61.0);
  const CGAffineTransform *transform = &transformValue;
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathMoveToPoint(path, transform, 30.001, 0.962);
  CGPathAddCurveToPoint(path, transform, 13.439, 0.962, 0.014, 13.462, 0.014, 28.882);
  CGPathAddCurveToPoint(path, transform, 0.014, 37.165, 3.892, 44.516, 10.046, 49.549);
  CGPathAddLineToPoint(path, transform, 10.046, 61.176);
  CGPathAddLineToPoint(path, transform, 19.351, 54.722);
  CGPathAddCurveToPoint(path, transform, 22.662, 55.870, 26.250, 56.502, 30.002, 56.502);
  CGPathAddCurveToPoint(path, transform, 46.565, 56.502, 59.990, 44.301, 59.990, 28.882);
  CGPathAddCurveToPoint(path, transform, 59.989, 13.462, 46.564, 0.962, 30.001, 0.962);
  CGPathCloseSubpath(path);
  CGPathMoveToPoint(path, transform, 33.159, 37.473);
  CGPathAddLineToPoint(path, transform, 25.403, 29.484);
  CGPathAddLineToPoint(path, transform, 10.467, 37.674);
  CGPathAddLineToPoint(path, transform, 26.843, 20.445);
  CGPathAddLineToPoint(path, transform, 34.599, 28.433);
  CGPathAddLineToPoint(path, transform, 49.535, 20.244);
  CGPathAddLineToPoint(path, transform, 33.159, 37.473);
  CGPathCloseSubpath(path);
  CGPathRef result = CGPathCreateCopy(path);
  CGPathRelease(path);
  return CFAutorelease(result);
}

@end

#endif
