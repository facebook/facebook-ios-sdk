/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKDevicePoller.h"

@implementation FBSDKDevicePoller

- (void)scheduleBlock:(dispatch_block_t)block interval:(NSUInteger)interval
{
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    block
  );
}

@end
