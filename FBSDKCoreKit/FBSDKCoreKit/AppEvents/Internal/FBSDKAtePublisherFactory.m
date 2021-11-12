/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAtePublisherFactory.h"

#import "FBSDKAppEventsAtePublisher.h"
#import "FBSDKDataPersisting.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAtePublisherFactory ()

@property (nonatomic, readonly) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonatomic, readonly) id<FBSDKSettings> settings;
@property (nonatomic, readonly) id<FBSDKDataPersisting> store;
@property (nonatomic, readonly) id<FBSDKDeviceInformationProviding> deviceInformationProvider;

@end

@implementation FBSDKAtePublisherFactory

- (instancetype)initWithStore:(id<FBSDKDataPersisting>)store
          graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                     settings:(id<FBSDKSettings>)settings
    deviceInformationProvider:(id<FBSDKDeviceInformationProviding>)deviceInformationProvider
{
  if ((self = [super init])) {
    _store = store;
    _graphRequestFactory = graphRequestFactory;
    _settings = settings;
    _deviceInformationProvider = deviceInformationProvider;
  }
  return self;
}

- (nullable id<FBSDKAtePublishing>)createPublisherWithAppID:(NSString *)appID
{
  return [[FBSDKAppEventsAtePublisher alloc] initWithAppIdentifier:appID
                                               graphRequestFactory:self.graphRequestFactory
                                                          settings:self.settings
                                                             store:self.store
                                         deviceInformationProvider:self.deviceInformationProvider];
}

@end

NS_ASSUME_NONNULL_END
