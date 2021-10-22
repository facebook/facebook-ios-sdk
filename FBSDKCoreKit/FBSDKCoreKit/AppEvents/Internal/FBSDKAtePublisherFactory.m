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

@property (nonnull, nonatomic, readonly) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonnull, nonatomic, readonly) id<FBSDKSettings> settings;
@property (nonnull, nonatomic, readonly) id<FBSDKDataPersisting> store;

@end

@implementation FBSDKAtePublisherFactory

- (instancetype)initWithStore:(id<FBSDKDataPersisting>)store
          graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                     settings:(id<FBSDKSettings>)settings
{
  if ((self = [super init])) {
    _store = store;
    _graphRequestFactory = graphRequestFactory;
    _settings = settings;
  }
  return self;
}

- (nullable id<FBSDKAtePublishing>)createPublisherWithAppID:(NSString *)appID
{
  return [[FBSDKAppEventsAtePublisher alloc] initWithAppIdentifier:appID
                                               graphRequestFactory:self.graphRequestFactory
                                                          settings:self.settings
                                                             store:self.store];
}

@end

NS_ASSUME_NONNULL_END
