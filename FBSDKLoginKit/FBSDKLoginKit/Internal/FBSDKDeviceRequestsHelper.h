/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define FBSDK_DEVICE_INFO_PARAM @"device_info"

/*
 @class

  Helper class for device requests mDNS broadcasts. Note this is only intended for
 internal consumption.
 */
NS_SWIFT_NAME(DeviceRequestsHelper)
@interface FBSDKDeviceRequestsHelper : NSObject

/**
  Get device info to include with the GraphRequest
 */
@property (class, nonatomic, readonly, copy) NSString *getDeviceInfo;

/**
  Start the mDNS advertisement service for a device request
 @param loginCode The login code associated with the action for the device request.
 @return True if the service broadcast was successfully started.
 */
+ (BOOL)startAdvertisementService:(NSString *)loginCode withDelegate:(id<NSNetServiceDelegate>)delegate;

/**
  Check if a service delegate is registered with particular advertisement service
 @param delegate The delegate to check if registered.
 @param service The advertisement service to check for.
 @return True if the service is the one the delegate registered with.
 */
+ (BOOL)isDelegate:(id<NSNetServiceDelegate>)delegate forAdvertisementService:(NSNetService *)service;

/**
  Stop the mDNS advertisement service for a device request
 @param delegate The delegate registered with the service.
 */
+ (void)cleanUpAdvertisementService:(id<NSNetServiceDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
