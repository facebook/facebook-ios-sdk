/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKMonotonicTime.h"

#include <assert.h>
#include <dispatch/dispatch.h>
#include <mach/mach.h>
#include <mach/mach_time.h>

#import <FBSDKLoginKit/FBSDKLoginKit-Swift.h>

static uint64_t _get_time_nanoseconds(void)
{
  static struct mach_timebase_info tb_info = {0};
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    int ret = mach_timebase_info(&tb_info);
    assert(0 == ret);
  });

  return (mach_absolute_time() * tb_info.numer) / tb_info.denom;
}

FBSDKMonotonicTimeSeconds FBSDKMonotonicTimeGetCurrentSeconds(void)
{
  const uint64_t nowNanoSeconds = _get_time_nanoseconds();
  return (FBSDKMonotonicTimeSeconds)nowNanoSeconds / (FBSDKMonotonicTimeSeconds)1000000000.0;
}

#endif
