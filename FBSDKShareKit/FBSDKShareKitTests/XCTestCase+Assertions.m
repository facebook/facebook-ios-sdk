/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "XCTestCase+Assertions.h"

@implementation XCTestCase (Assertions)

- (void)assertThrowsSpecificNamed:(NSExceptionName)exceptionName block:(void (^)(void))block
{
  XCTAssertThrowsSpecificNamed(block(), NSException, exceptionName);
}

@end
