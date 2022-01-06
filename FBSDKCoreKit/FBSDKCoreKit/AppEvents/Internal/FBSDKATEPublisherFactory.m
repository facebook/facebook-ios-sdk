/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKATEPublisherFactory.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAppEventsATEPublisher.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKATEPublisherFactory

- (instancetype)initWithDataStore:(id<FBSDKDataPersisting>)dataStore
              graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                         settings:(id<FBSDKSettings>)settings
        deviceInformationProvider:(id<FBSDKDeviceInformationProviding>)deviceInformationProvider
{
  if ((self = [super init])) {
    _dataStore = dataStore;
    _graphRequestFactory = graphRequestFactory;
    _settings = settings;
    _deviceInformationProvider = deviceInformationProvider;
  }
  return self;
}

- (nullable id<FBSDKATEPublishing>)createPublisherWithAppID:(NSString *)appID
{
  return [[FBSDKAppEventsATEPublisher alloc] initWithAppIdentifier:appID
                                               graphRequestFactory:self.graphRequestFactory
                                                          settings:self.settings
                                                             store:self.dataStore
                                         deviceInformationProvider:self.deviceInformationProvider];
}

@end

NS_ASSUME_NONNULL_END
