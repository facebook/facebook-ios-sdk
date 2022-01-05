/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKReferralManager+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKReferralManager (Testing)

@property (nonatomic) NSString *expectedChallenge;

- (NSURL *)referralURL;

- (void)handleOpenURLComplete:(BOOL)didOpen error:(nullable NSError *)error;

- (BOOL)validateChallenge:(NSString *)challenge;

@end

NS_ASSUME_NONNULL_END
