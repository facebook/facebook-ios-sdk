/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBAEMKit/FBAEMKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBAEMReporter (Testing)

@property (class, nullable, nonatomic) id<FBAEMNetworking> networker;
@property (class, nullable, nonatomic, copy) NSString *appID;
@property (class, nullable, nonatomic) id<FBSKAdNetworkReporting> reporter;

+ (void)reset;

@end

NS_ASSUME_NONNULL_END
