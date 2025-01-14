/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKGraphRequestConnection (Testing)

@property (class, nonatomic, readonly) BOOL canMakeRequests;
@property (class, nonatomic, readonly) BOOL didFetchDomainConfiguration;

+ (void)resetCanMakeRequests;
+ (void)resetDidFetchDomainConfiguration;
+ (void)resetDefaultConnectionTimeout;

- (NSString *)_overrideVersionPart;
- (BOOL)shouldPiggyBackRequests;

@end

NS_ASSUME_NONNULL_END
