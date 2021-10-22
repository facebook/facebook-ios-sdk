/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import "FBSDKLoginManagerLoginResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKLoginManagerLoginResult ()

@property (nonatomic, readonly) NSDictionary<NSString *, id> *loggingExtras;

// legacy flag indicating this is an intermediary result only for logging purposes.
@property (nonatomic, assign) BOOL isSkipped;

// adds additional logging entry to extras - only sent as part of `endLoginWithResult:`
- (void)addLoggingExtra:(id)object forKey:(id<NSCopying>)key;
@end

NS_ASSUME_NONNULL_END

#endif
