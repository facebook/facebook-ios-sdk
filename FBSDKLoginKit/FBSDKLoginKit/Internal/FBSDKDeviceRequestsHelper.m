/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKDeviceRequestsHelper.h"

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <sys/utsname.h>

#import <FBSDKLoginKit/FBSDKLoginKit-Swift.h>

#import "FBSDKLoginAppEventName.h"

#define FBSDK_DEVICE_INFO_DEVICE @"device"
#define FBSDK_DEVICE_INFO_MODEL @"model"
#define FBSDK_HEADER @"fbsdk"
#if !TARGET_OS_TV
 #define FBSDK_FLAVOR @"ios"
#else
 #define FBSDK_FLAVOR @"tvos"
#endif
#define FBSDK_SERVICE_TYPE @"_fb._tcp."

static NSMapTable *g_mdnsAdvertisementServices;

@implementation FBSDKDeviceRequestsHelper

#pragma mark - Class Methods

+ (void)initialize
{
  // We use weak to strong in order to retain the advertisement services
  // without having to pass them back to the delegate that started them
  // Note that in case the delegate is destroyed before it had a chance to
  // stop the service, the service will continue broadcasting until the map
  // resizes itself and releases the service, causing it to stop
  g_mdnsAdvertisementServices = [NSMapTable weakToStrongObjectsMapTable];
}

+ (NSString *)getDeviceInfo
{
  struct utsname systemInfo;
  uname(&systemInfo);
  NSDictionary<NSString *, NSString *> *deviceInfo = @{
    FBSDK_DEVICE_INFO_DEVICE : @(systemInfo.machine),
    FBSDK_DEVICE_INFO_MODEL : UIDevice.currentDevice.model,
  };
  NSError *err;
  NSData *jsonDeviceInfo = [FBSDKTypeUtility dataWithJSONObject:deviceInfo
                                                        options:0
                                                          error:&err];

  return [[NSString alloc] initWithData:jsonDeviceInfo encoding:NSUTF8StringEncoding];
}

+ (BOOL)startAdvertisementService:(NSString *)loginCode withDelegate:(id<NSNetServiceDelegate>)delegate
{
  static NSString *sdkVersion = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Dots in the version will mess up the bonjour DNS record parsing
    sdkVersion = [FBSDKSettings.sharedSettings.sdkVersion stringByReplacingOccurrencesOfString:@"." withString:@"|"];
    if (sdkVersion.length > 10
        || ![NSCharacterSet.decimalDigitCharacterSet characterIsMember:[sdkVersion characterAtIndex:0]]) {
      sdkVersion = @"dev";
    }
  });
  NSString *serviceName = [NSString stringWithFormat:@"%@_%@_%@",
                           FBSDK_HEADER,
                           [NSString stringWithFormat:@"%@-%@",
                            FBSDK_FLAVOR,
                            sdkVersion
                           ],
                           loginCode
  ];
  if (serviceName.length > 60) {
    return NO;
  }
  NSNetService *mdnsAdvertisementService = [[NSNetService alloc]
                                            initWithDomain:@"local."
                                            type:FBSDK_SERVICE_TYPE
                                            name:serviceName
                                            port:0];
  mdnsAdvertisementService.delegate = delegate;
  [mdnsAdvertisementService publishWithOptions:NSNetServiceNoAutoRename | NSNetServiceListenForConnections];
  [FBSDKAppEvents.shared logInternalEvent:FBSDKAppEventNameFBSDKSmartLoginService
                               parameters:@{}
                       isImplicitlyLogged:YES];
  [g_mdnsAdvertisementServices setObject:mdnsAdvertisementService forKey:delegate];

  return YES;
}

+ (BOOL)isDelegate:(id<NSNetServiceDelegate>)delegate forAdvertisementService:(NSNetService *)service
{
  NSNetService *mdnsAdvertisementService = [g_mdnsAdvertisementServices objectForKey:delegate];
  return (mdnsAdvertisementService == service);
}

+ (void)cleanUpAdvertisementService:(id<NSNetServiceDelegate>)delegate
{
  NSNetService *mdnsAdvertisementService = [g_mdnsAdvertisementServices objectForKey:delegate];
  if (mdnsAdvertisementService != nil) {
    // We are not interested in the stop publish event
    mdnsAdvertisementService.delegate = nil;
    [mdnsAdvertisementService stop];
    [g_mdnsAdvertisementServices removeObjectForKey:delegate];
  }
}

@end
