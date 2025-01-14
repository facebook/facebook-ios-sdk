/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_EventsProcessing)
@protocol FBSDKEventsProcessing

- (void)enable;
- (void)processEvents:(NSMutableArray<NSDictionary<NSString *, id> *> *)events;

@end

NS_ASSUME_NONNULL_END
