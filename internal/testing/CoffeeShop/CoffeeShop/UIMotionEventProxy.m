// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "UIMotionEventProxy.h"

@implementation UIMotionEventProxy

- (void)setShakeState:(int)fp8
{
  _shakeState = fp8;
}

- (void)_setSubtype:(int)fp8
{
  _subtype = fp8;
}

@end
