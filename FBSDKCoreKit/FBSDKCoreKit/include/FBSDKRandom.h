/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

/**
 Provides a random string
 @param numberOfBytes the number of bytes to use
 */
extern NSString *fb_randomString(NSUInteger numberOfBytes);
