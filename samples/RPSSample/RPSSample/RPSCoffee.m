/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RPSCoffee.h"

@implementation Coffee

- (instancetype)initWithName:(NSString *)name desc:(NSString *)desc price:(float)price
{
  if ((self = [super init])) {
    _name = [name copy];
    _desc = [desc copy];
    _price = price;
  }
  return self;
}

@end
