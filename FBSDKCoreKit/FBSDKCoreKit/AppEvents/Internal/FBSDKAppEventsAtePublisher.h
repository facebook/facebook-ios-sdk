/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKAtePublishing.h"

@protocol FBSDKDataPersisting;
@protocol FBSDKGraphRequestFactory;
@protocol FBSDKSettings;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppEventsAtePublisher)
@interface FBSDKAppEventsAtePublisher : NSObject <FBSDKAtePublishing>

@property (nonatomic, readonly) NSString *appIdentifier;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithAppIdentifier:(NSString *)appIdentifier
                           graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                                      settings:(id<FBSDKSettings>)settings
                                         store:(id<FBSDKDataPersisting>)store;

- (void)publishATE;

@end

NS_ASSUME_NONNULL_END
