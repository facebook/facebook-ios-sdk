/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "XCTestCase+Extensions.h"

@implementation XCTestCase (Testing)

- (void)assertRaisesExceptionWithMessage:(NSString *)message block:(void (^)(void))block
{
  XCTAssertThrows(block(), @"%@", message);
}

- (void)assertDoesNotRaiseExceptionWithMessage:(NSString *)message block:(void (^)(void))block
{
  XCTAssertNoThrow(block(), @"%@", message);
}

@end
