/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

 #import <Foundation/Foundation.h>
 #import "FBSDKConversionValueUpdating.h"
 #import "FBSDKSKAdNetworkReporter.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKSKAdNetworkReporter (Internal)

- (instancetype)initWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                               store:(id<FBSDKDataPersisting>)store
            conversionValueUpdatable:(Class<FBSDKConversionValueUpdating>)conversionValueUpdatable
NS_SWIFT_NAME(init(graphRequestFactory:store:conversionValueUpdateable:));

@end

NS_ASSUME_NONNULL_END

#endif
