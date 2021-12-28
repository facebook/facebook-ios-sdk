/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKATEPublishing.h"
#import "FBSDKDeviceInformationProviding.h"

@protocol FBSDKDataPersisting;
@protocol FBSDKGraphRequestFactory;
@protocol FBSDKSettings;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppEventsATEPublisher)
@interface FBSDKAppEventsATEPublisher : NSObject <FBSDKATEPublishing>

@property (nonatomic, readonly) NSString *appIdentifier;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithAppIdentifier:(NSString *)appIdentifier
                           graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                                      settings:(id<FBSDKSettings>)settings
                                         store:(id<FBSDKDataPersisting>)store
                     deviceInformationProvider:(id<FBSDKDeviceInformationProviding>)deviceInformationProvider;
- (void)publishATE;

@end

NS_ASSUME_NONNULL_END
