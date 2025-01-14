/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit-Swift.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import <sys/sysctl.h>
#import <sys/utsname.h>

#if !TARGET_OS_TV
 #import <CoreTelephony/CTCarrier.h>
 #import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKInternalUtility+Internal.h"

#define FB_ARRAY_COUNT(x) sizeof(x) / sizeof(x[0])

static const u_int FB_GROUP1_RECHECK_DURATION = 30 * 60; // seconds

@interface FBSDKAppEventsDeviceInfo ()

// Other state
@property (nonatomic) long lastGroup1CheckTime;
@property (nonatomic) BOOL isEncodingDirty;

// Dependencies
@property (nullable, nonatomic) id<FBSDKSettings> settings;
@end

@implementation FBSDKAppEventsDeviceInfo

@synthesize encodedDeviceInfo = _encodedDeviceInfo;

#pragma mark - Public Methods

static dispatch_once_t singletonNonce;
static FBSDKAppEventsDeviceInfo *sharedInstance;
+ (instancetype)shared
{
  dispatch_once(&singletonNonce, ^{
    sharedInstance = [FBSDKAppEventsDeviceInfo new];
  });
  return sharedInstance;
}

- (void)configureWithSettings:(id<FBSDKSettings>)settings
{
  self.settings = settings;
  self.isEncodingDirty = YES;

  [self _collectPersistentData];
}

- (NSString *)storageKey
{
  return @"extinfo";
}

#pragma mark - Internal Methods

- (nullable NSString *)encodedDeviceInfo
{
  @synchronized(self) {
    BOOL isGroup1Expired = [self _isGroup1Expired];
    BOOL isEncodingExpired = isGroup1Expired; // Can || other groups in if we add them

    // As long as group1 hasn't expired, we can just return the last generated value
    if (_encodedDeviceInfo && !isEncodingExpired) {
      return _encodedDeviceInfo;
    }

    if (isGroup1Expired) {
      [self _collectGroup1Data];
    }

    if (_isEncodingDirty) {
      _encodedDeviceInfo = [self _generateEncoding];
      _isEncodingDirty = NO;
    }

    return _encodedDeviceInfo;
  }
}

// This data need only be collected once.
- (void)_collectPersistentData
{
  // Bundle stuff
  NSBundle *mainBundle = NSBundle.mainBundle;
  self.bundleIdentifier = mainBundle.bundleIdentifier;
  self.longVersion = [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
  self.shortVersion = [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

  // Locale stuff
  self.language = NSLocale.currentLocale.localeIdentifier;

  // Device stuff
  UIDevice *device = [UIDevice currentDevice];
  self.sysVersion = device.systemVersion;
  self.coreCount = [FBSDKAppEventsDeviceInfo _readCoreCount];

  UIScreen *sc = [UIScreen mainScreen];
  CGRect sr = sc.bounds;
  self.width = sr.size.width;
  self.height = sr.size.height;
  self.density = sc.scale;

  struct utsname systemInfo;
  uname(&systemInfo);
  self.machine = @(systemInfo.machine);
}

- (BOOL)_isGroup1Expired
{
  return ([self unixTimeNow] - self.lastGroup1CheckTime) > FB_GROUP1_RECHECK_DURATION;
}

// This data is collected only once every GROUP1_RECHECK_DURATION.
- (void)_collectGroup1Data
{
  const BOOL shouldUseCachedValues = self.settings.shouldUseCachedValuesForExpensiveMetadata;

  if (!self.carrierName || !shouldUseCachedValues) {
    NSString *newCarrierName = [FBSDKAppEventsDeviceInfo _getCarrier];
    if (!self.carrierName || ![newCarrierName isEqualToString:self.carrierName]) {
      self.carrierName = newCarrierName;
      self.isEncodingDirty = YES;
    }
  }

  if (!self.timeZoneName || !self.timeZoneAbbrev || !shouldUseCachedValues) {
    NSTimeZone *timeZone = NSTimeZone.systemTimeZone;
    NSString *timeZoneName = timeZone.name;
    if (!self.timeZoneName || ![timeZoneName isEqualToString:self.timeZoneName]) {
      self.timeZoneName = timeZoneName;
      self.timeZoneAbbrev = timeZone.abbreviation;
      self.isEncodingDirty = YES;
    }
  }

  self.lastGroup1CheckTime = [self unixTimeNow];
}

- (nullable NSString *)_generateEncoding
{
  // Keep a bit of precision on density as it's the most likely to become non-integer.
  NSString *densityString = _density ? [NSString stringWithFormat:@"%.02f", _density] : @"";

  NSArray<id> *arr = @[
    @"i2", // version - starts with 'i' for iOS, we'll use 'a' for Android
    self.bundleIdentifier ?: @"",
    self.longVersion ?: @"",
    self.shortVersion ?: @"",
    self.sysVersion ?: @"",
    self.machine ?: @"",
    self.language ?: @"",
    self.timeZoneAbbrev ?: @"",
    self.carrierName ?: @"",
    self.width ? @((unsigned long)self.width) : @"",
    self.height ? @((unsigned long)self.height) : @"",
    densityString,
    @(self.coreCount) ?: @"",
    @-1,
    @-1,
    self.timeZoneName ?: @""
  ];

  return [FBSDKBasicUtility JSONStringForObject:arr
                                          error:NULL
                           invalidObjectHandler:NULL];
}

- (NSTimeInterval)unixTimeNow
{
  return round([NSDate date].timeIntervalSince1970);
}

+ (uint)_readCoreCount
{
  int mib[2] = {CTL_HW, HW_AVAILCPU};
  uint value;
  size_t size = sizeof value;
  if (0 != sysctl(mib, FB_ARRAY_COUNT(mib), &value, &size, NULL, 0)) {
    return 0;
  }
  return value;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (NSString *)_getCarrier
{
#if TARGET_OS_SIMULATOR
  return @"NoCarrier";
#else
  // Dynamically load class for this so calling app doesn't need to link framework in.
  CTTelephonyNetworkInfo *networkInfo = [[fbsdkdfl_CTTelephonyNetworkInfoClass() alloc] init];
  CTCarrier *carrier = networkInfo.subscriberCellularProvider;
  return carrier.carrierName ?: @"NoCarrier";
#endif
}

#pragma clang diagnostic pop

#if DEBUG
- (void)resetDependencies
{
  self.settings = nil;
}

#endif

@end
