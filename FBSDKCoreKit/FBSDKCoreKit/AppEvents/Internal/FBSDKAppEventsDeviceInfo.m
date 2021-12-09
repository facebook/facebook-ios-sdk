/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppEventsDeviceInfo.h"

#import <sys/sysctl.h>
#import <sys/utsname.h>

#if !TARGET_OS_TV
 #import <CoreTelephony/CTCarrier.h>
 #import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAppEventsUtility.h"
#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKSettings+Internal.h"

#define FB_ARRAY_COUNT(x) sizeof(x) / sizeof(x[0])

static const u_int FB_GROUP1_RECHECK_DURATION = 30 * 60; // seconds

// Apple reports storage in binary gigabytes (1024^3) in their About menus, etc.
static const u_int FB_GIGABYTE = 1024 * 1024 * 1024; // bytes

@interface FBSDKAppEventsDeviceInfo ()

// Ephemeral data, may change during the lifetime of an app.  We collect them in different
// 'group' frequencies - group1 may gets collected once every 30 minutes.

// group1
@property (nonatomic) NSString *carrierName;
@property (nonatomic) NSString *timeZoneAbbrev;
@property (nonatomic) unsigned long long remainingDiskSpaceGB;
@property (nonatomic) NSString *timeZoneName;

// Persistent data, but we maintain it to make rebuilding the device info as fast as possible.
@property (nonatomic) NSString *bundleIdentifier;
@property (nonatomic) NSString *longVersion;
@property (nonatomic) NSString *shortVersion;
@property (nonatomic) NSString *sysVersion;
@property (nonatomic) NSString *machine;
@property (nonatomic) NSString *language;
@property (nonatomic) unsigned long long totalDiskSpaceGB;
@property (nonatomic) unsigned long long coreCount;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat density;

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

  // Disk space stuff
  float totalDiskSpace = [FBSDKAppEventsDeviceInfo _getTotalDiskSpace].floatValue;
  self.totalDiskSpaceGB = (unsigned long long)round(totalDiskSpace / FB_GIGABYTE);
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

  // Remaining disk space
  float remainingDiskSpace = [FBSDKAppEventsDeviceInfo _getRemainingDiskSpace].floatValue;
  unsigned long long newRemainingDiskSpaceGB = (unsigned long long)round(remainingDiskSpace / FB_GIGABYTE);
  if (self.remainingDiskSpaceGB != newRemainingDiskSpaceGB) {
    self.remainingDiskSpaceGB = newRemainingDiskSpaceGB;
    self.isEncodingDirty = YES;
  }

  self.lastGroup1CheckTime = [self unixTimeNow];
}

- (nullable NSString *)_generateEncoding
{
  // Keep a bit of precision on density as it's the most likely to become non-integer.
  NSString *densityString = _density ? [NSString stringWithFormat:@"%.02f", _density] : @"";

  NSArray *arr = @[
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
    @(self.totalDiskSpaceGB) ?: @"",
    @(self.remainingDiskSpaceGB) ?: @"",
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

+ (NSNumber *)_getTotalDiskSpace
{
  NSDictionary<NSString *, id> *attrs = [[NSFileManager new] attributesOfFileSystemForPath:NSHomeDirectory()
                                                                                     error:nil];
  return attrs[NSFileSystemSize];
}

+ (NSNumber *)_getRemainingDiskSpace
{
  NSDictionary<NSString *, id> *attrs = [[NSFileManager new] attributesOfFileSystemForPath:NSHomeDirectory()
                                                                                     error:nil];
  return attrs[NSFileSystemFreeSize];
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
#if TARGET_OS_TV || TARGET_OS_SIMULATOR
  return @"NoCarrier";
#else
  // Dynamically load class for this so calling app doesn't need to link framework in.
  CTTelephonyNetworkInfo *networkInfo = [[fbsdkdfl_CTTelephonyNetworkInfoClass() alloc] init];
  CTCarrier *carrier = networkInfo.subscriberCellularProvider;
  return carrier.carrierName ?: @"NoCarrier";
#endif
}

#pragma clang diagnostic pop

#if FBTEST && DEBUG
+ (void)reset
{
  if (singletonNonce) {
    singletonNonce = 0;
  }
}

#endif

@end
