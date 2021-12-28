/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKTransformer.h"

#import "FBSDKDynamicFrameworkLoader.h"

CATransform3D const FBSDKCATransform3DIdentity = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1};

@implementation FBSDKTransformer

- (CATransform3D)CATransform3DMakeScale:(CGFloat)sx sy:(CGFloat)sy sz:(CGFloat)sz
{
  return fbsdkdfl_CATransform3DMakeScale(sx, sy, sz);
}

- (CATransform3D)CATransform3DMakeTranslation:(CGFloat)tx ty:(CGFloat)ty tz:(CGFloat)tz
{
  return fbsdkdfl_CATransform3DMakeTranslation(tx, ty, tz);
}

- (CATransform3D)CATransform3DConcat:(CATransform3D)a b:(CATransform3D)b
{
  return fbsdkdfl_CATransform3DConcat(a, b);
}

@end
