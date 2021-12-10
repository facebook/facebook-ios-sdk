/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
Internal Type exposed to facilitate transition to Swift.
API Subject to change or removal without warning. Do not use.

@warning INTERNAL - DO NOT USE
*/
@interface FBSDKLoginTooltip : NSObject
@property (nonatomic, readonly, getter = isEnabled, assign) BOOL enabled;
@property (nonatomic, readonly, copy) NSString *text;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithText:(NSString *)text
                     enabled:(BOOL)enabled
  NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
