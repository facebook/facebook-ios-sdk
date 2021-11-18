/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKATEPublisherCreating.h"
#import "FBSDKDeviceInformationProviding.h"

@protocol FBSDKDataPersisting;
@protocol FBSDKGraphRequestFactory;
@protocol FBSDKSettings;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ATEPublisherFactory)
@interface FBSDKATEPublisherFactory : NSObject <FBSDKATEPublisherCreating>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithStore:(id<FBSDKDataPersisting>)store
          graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                     settings:(id<FBSDKSettings>)settings
    deviceInformationProvider:(id<FBSDKDeviceInformationProviding>)deviceInformationProvider;

@end

NS_ASSUME_NONNULL_END
