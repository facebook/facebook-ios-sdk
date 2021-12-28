/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBAEMKit/FBAEMKit.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AEMNetworker)
@interface FBSDKAEMNetworker : NSObject <FBAEMNetworking>

- (void)startGraphRequestWithGraphPath:(NSString *)graphPath
                            parameters:(NSDictionary<NSString *, id> *)parameters
                           tokenString:(nullable NSString *)tokenString
                            HTTPMethod:(nullable NSString *)method
                            completion:(FBGraphRequestCompletion)completion;

@end

NS_ASSUME_NONNULL_END

#endif
