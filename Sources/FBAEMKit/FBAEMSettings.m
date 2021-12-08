/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBAEMSettings.h"

static NSString *const APPID_KEY = @"FacebookAppID";

@implementation FBAEMSettings

+ (nullable NSString *)appID
{
  return [[[NSBundle mainBundle] objectForInfoDictionaryKey:APPID_KEY] copy] ?: nil;
}

@end

#endif
