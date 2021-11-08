/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAuthenticationTokenHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAuthenticationTokenHeader (Testing)

- (instancetype)initWithAlg:(NSString *)alg
                        typ:(NSString *)typ
                        kid:(NSString *)kid;

@end

NS_ASSUME_NONNULL_END
