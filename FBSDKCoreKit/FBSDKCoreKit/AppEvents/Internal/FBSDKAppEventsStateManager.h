/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsStatePersisting.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppEventsStateManager)
@interface FBSDKAppEventsStateManager : NSObject <FBSDKAppEventsStatePersisting>

@property (class, nonatomic, readonly) FBSDKAppEventsStateManager *shared;

- (void)clearPersistedAppEventsStates;

// reads all saved event states, appends the param, and writes them all.
- (void)persistAppEventsData:(FBSDKAppEventsState *)appEventsState;

// returns the array of saved app event states and deletes them.
- (NSArray *)retrievePersistedAppEventsStates;

@end
NS_ASSUME_NONNULL_END
