/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppEventsParameterProcessing.h"
#import "FBSDKEventsProcessing.h"
#import "FBSDKRestrictiveDataFilterManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKRestrictiveDataFilterManager (AppEventsParameterProcessing) <FBSDKAppEventsParameterProcessing, FBSDKEventsProcessing>
@end

NS_ASSUME_NONNULL_END
