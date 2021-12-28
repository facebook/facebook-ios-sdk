/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
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

@property (nonatomic) id<FBSDKDataPersisting> dataStore;
@property (nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonatomic) id<FBSDKSettings> settings;
@property (nonatomic) id<FBSDKDeviceInformationProviding> deviceInformationProvider;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDataStore:(id<FBSDKDataPersisting>)dataStore
              graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                         settings:(id<FBSDKSettings>)settings
        deviceInformationProvider:(id<FBSDKDeviceInformationProviding>)deviceInformationProvider;

@end

NS_ASSUME_NONNULL_END
