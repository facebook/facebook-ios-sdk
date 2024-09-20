/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

extern CATransform3D const FBSDKCATransform3DIdentity;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@interface FBSDKTransformer : NSObject
- (CATransform3D)CATransform3DMakeScale:(CGFloat)sx sy:(CGFloat)sy sz:(CGFloat)sz;
- (CATransform3D)CATransform3DMakeTranslation:(CGFloat)tx ty:(CGFloat)ty tz:(CGFloat)tz;
- (CATransform3D)CATransform3DConcat:(CATransform3D)a b:(CATransform3D)b;
@end

NS_ASSUME_NONNULL_END
