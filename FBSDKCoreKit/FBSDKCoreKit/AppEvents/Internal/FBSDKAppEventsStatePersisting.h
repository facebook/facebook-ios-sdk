/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@class FBSDKAppEventsState;

NS_ASSUME_NONNULL_BEGIN
NS_SWIFT_NAME(AppEventsStatePersisting)
@protocol FBSDKAppEventsStatePersisting

- (void)clearPersistedAppEventsStates;
- (void)persistAppEventsData:(FBSDKAppEventsState *)appEventsState;
// patternlint-disable-next-line objc-headers-collection-generics
- (NSArray *)retrievePersistedAppEventsStates; // NSArray<FBSDKAppEventsState *>

@end
NS_ASSUME_NONNULL_END
