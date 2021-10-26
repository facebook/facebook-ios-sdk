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

NS_ASSUME_NONNULL_BEGIN

typedef void (^FBGraphRequestCompletion)(id _Nullable result, NSError *_Nullable error);

NS_SWIFT_NAME(AEMNetworking)
@protocol FBAEMNetworking

- (void)startGraphRequestWithGraphPath:(NSString *)graphPath
                            parameters:(NSDictionary<NSString *, id> *)parameters
                           tokenString:(nullable NSString *)tokenString
                            HTTPMethod:(nullable NSString *)method
                            completion:(FBGraphRequestCompletion)completion;

@end

NS_ASSUME_NONNULL_END

#endif
