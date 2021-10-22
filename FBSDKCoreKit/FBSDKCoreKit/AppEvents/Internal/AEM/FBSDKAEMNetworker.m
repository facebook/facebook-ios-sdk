/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAEMNetworker.h"

#import <Foundation/Foundation.h>

#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequestFlags.h"

@implementation FBSDKAEMNetworker

- (void)startGraphRequestWithGraphPath:(NSString *)graphPath
                            parameters:(NSDictionary<NSString *, id> *)parameters
                           tokenString:(nullable NSString *)tokenString
                            HTTPMethod:(nullable NSString *)method
                            completion:(FBGraphRequestCompletion)completion
{
  id<FBSDKGraphRequest> graphRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                                                         parameters:parameters
                                                                        tokenString:tokenString
                                                                         HTTPMethod:method
                                                                              flags:FBSDKGraphRequestFlagSkipClientToken | FBSDKGraphRequestFlagDisableErrorRecovery];

  [graphRequest startWithCompletion:^(id<FBSDKGraphRequestConnecting> _Nullable connection, id _Nullable result, NSError *_Nullable error) {
    completion(result, error);
  }];
}

@end

#endif
