/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#include <stdint.h>

typedef double FBSDKMonotonicTimeSeconds;

/**
 * return current monotonic time in Seconds
 * Nanosecond precision, double value.
 * Should be preferred over FBSDKMonotonicTimeGetCurrentMilliseconds in case
 * nanosecond precision is required.
 * IMPORTANT: this timer doesn't run while the device is sleeping.
 */
FBSDKMonotonicTimeSeconds FBSDKMonotonicTimeGetCurrentSeconds(void);

#endif
