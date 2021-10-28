/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKSharing.h"

NS_ASSUME_NONNULL_BEGIN

@interface FakeSharingDelegate : NSObject <FBSDKSharingDelegate>

@property (nonatomic) NSDictionary<NSString *, id> *capturedResults;
@property (nonatomic) NSError *capturedError;
@property (nonatomic) BOOL didCancel;

@end

NS_ASSUME_NONNULL_END
