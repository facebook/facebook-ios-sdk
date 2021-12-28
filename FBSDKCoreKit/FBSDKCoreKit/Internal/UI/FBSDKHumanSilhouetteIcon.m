/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKHumanSilhouetteIcon.h"

@implementation FBSDKHumanSilhouetteIcon

- (CGPathRef)pathWithSize:(CGSize)size
{
  CGAffineTransform transformValue = CGAffineTransformMakeScale(size.width / 158.783, size.height / 158.783);
  CGAffineTransform *transform = &transformValue;
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathMoveToPoint(path, transform, 158.783, 158.783);
  CGPathAddCurveToPoint(path, transform, 156.39, 131.441, 144.912, 136.964, 105.607, 117.32);
  CGPathAddCurveToPoint(path, transform, 103.811, 113.941, 103.348, 108.8965, 103.013, 107.4781);
  CGPathAddLineToPoint(path, transform, 100.434, 106.7803);
  CGPathAddCurveToPoint(path, transform, 97.2363, 82.7701, 100.67, 101.5845, 106.006, 75.2188);
  CGPathAddCurveToPoint(path, transform, 107.949, 76.2959, 108.268, 70.7417, 108.971, 66.5743);
  CGPathAddCurveToPoint(path, transform, 109.673, 62.4068, 110.864, 58.9082, 107.139, 58.9082);
  CGPathAddCurveToPoint(path, transform, 107.94, 42.7652, 110.299, 31.3848, 101.335, 23.3072);
  CGPathAddCurveToPoint(path, transform, 92.3808, 15.23781, 87.874, 15.52349, 95.0483, 9.6036128);
  CGPathAddCurveToPoint(path, transform, 91.2319, 8.892613, 70.2036, 12.01861, 57.4487, 23.3072);
  CGPathAddCurveToPoint(path, transform, 48.4121, 31.3042, 50.8437, 42.7652, 51.6445, 58.9082);
  CGPathAddCurveToPoint(path, transform, 47.9194, 58.9082, 49.1108, 62.4068, 49.813, 66.5743);
  CGPathAddCurveToPoint(path, transform, 50.5156, 70.7417, 50.8349, 76.2959, 52.7778, 75.2188);
  CGPathAddCurveToPoint(path, transform, 58.1138, 110.1135, 61.5478, 82.7701, 58.3501, 106.7803);
  CGPathAddLineToPoint(path, transform, 55.7705, 107.4781);
  CGPathAddCurveToPoint(path, transform, 55.4355, 108.8965, 54.9722, 113.941, 53.1767, 117.32);
  CGPathAddCurveToPoint(path, transform, 13.8711, 136.964, 2.3945, 131.441, 0.0, 158.783);
  CGPathAddLineToPoint(path, transform, 158.783, 158.783);
  CGPathRef result = CGPathCreateCopy(path);
  CGPathRelease(path);
  return CFAutorelease(result);
}

@end

#endif
