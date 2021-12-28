/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKLoginTooltip.h"

@implementation FBSDKLoginTooltip

- (instancetype)initWithText:(NSString *)text
                     enabled:(BOOL)enabled
{
  if ((self = [super init])) {
    _text = [text copy];
    _enabled = enabled;
  }
  return self;
}

@end
