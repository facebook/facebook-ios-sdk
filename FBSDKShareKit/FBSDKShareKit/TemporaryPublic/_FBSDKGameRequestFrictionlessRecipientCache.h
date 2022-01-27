/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(GameRequestFrictionlessRecipientCache)
@interface FBSDKGameRequestFrictionlessRecipientCache : NSObject

- (BOOL)recipientsAreFrictionless:(id)recipients;
- (void)updateWithResults:(NSDictionary<NSString *, id> *)results;

@end

NS_ASSUME_NONNULL_END

#endif
