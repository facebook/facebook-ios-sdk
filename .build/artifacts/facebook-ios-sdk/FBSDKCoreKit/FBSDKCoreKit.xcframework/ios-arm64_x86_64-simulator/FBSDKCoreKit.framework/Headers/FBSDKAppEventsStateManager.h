/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKAppEventsStatePersisting.h>
#import <Foundation/Foundation.h>

@class FBSDKAppEventsState;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AppEventsStateManager)
@interface FBSDKAppEventsStateManager : NSObject <FBSDKAppEventsStatePersisting>

@property (class, nonatomic, readonly) FBSDKAppEventsStateManager *shared;

- (void)clearPersistedAppEventsStates;

// reads all saved event states, appends the param, and writes them all.
- (void)persistAppEventsData:(FBSDKAppEventsState *)appEventsState;

// returns the array of saved app event states and deletes them.
- (NSArray<FBSDKAppEventsState *> *)retrievePersistedAppEventsStates;

@end
NS_ASSUME_NONNULL_END
