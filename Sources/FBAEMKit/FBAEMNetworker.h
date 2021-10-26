/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import <Foundation/Foundation.h>

 #import "FBAEMNetworking.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AEMNetworker)
@interface FBAEMNetworker : NSObject <FBAEMNetworking, NSURLSessionDataDelegate>

- (void)startGraphRequestWithGraphPath:(NSString *)graphPath
                            parameters:(NSDictionary<NSString *, id> *)parameters
                           tokenString:(nullable NSString *)tokenString
                            HTTPMethod:(nullable NSString *)method
                            completion:(FBGraphRequestCompletion)completion;

@end

NS_ASSUME_NONNULL_END

#endif
