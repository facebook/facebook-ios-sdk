/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBAmbientDeviceInfo.h"

#import <sys/sysctl.h>
#import <sys/utsname.h>

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>

#import "FBAppEvents+Internal.h"
#import "FBDynamicFrameworkLoader.h"
#import "FBUtility.h"

#define ARRAY_COUNT(x) sizeof(x) / sizeof(x[0])

// Pack small numeric values into a long.  Below total to 51 bits, so we're good
// with a long long.
//
// uiIdiom - only two values, use 2 bits to be safe
// multiTasking supported - 1 bit
// width - let's go with 12 bits, will allow up to 4096
// height - same, 12 bits
// density - really 1 or 2, but use 2 bits to be safe.
// core count - 4 bits should be safe
// disk space in GB - 10 gets us to 1TB, should be fine
// disk remaining - decile, can only be between 0 and 10, 4 bits will do
// battery level - decile, can only be between 0 and 10, 4 bits will do

const ushort MASK_UI_IDIOM             = 0x0003;  // 2 bits
const ushort MASK_MULTITASKING         = 0x0001;  // 1 bit
const ushort MASK_WIDTH                = 0x0FFF;  // 12 bits
const ushort MASK_HEIGHT               = 0x0FFF;  // 12 bits
const ushort MASK_DENSITY              = 0x0003;  // 2 bits
const ushort MASK_CORE_COUNT           = 0x000F;  // 4 bits
const ushort MASK_TOTAL_DISK_SPACE     = 0x03FF;  // 10 bits
const ushort MASK_REMAINING_DISK_SPACE = 0x000F;  // 4 bits
const ushort MASK_BATTERY_LEVEL        = 0x000F;  // 4 bits

const ushort SHIFT_UI_IDIOM             = 0;                              // 2 bits
const ushort SHIFT_MULTITASKING         = SHIFT_UI_IDIOM + 2;             // 1 bit
const ushort SHIFT_WIDTH                = SHIFT_MULTITASKING + 1;         // 12 bits
const ushort SHIFT_HEIGHT               = SHIFT_WIDTH + 12;               // 12 bits
const ushort SHIFT_DENSITY              = SHIFT_HEIGHT + 12;              // 2 bits
const ushort SHIFT_CORE_COUNT           = SHIFT_DENSITY + 2;              // 4 bits
const ushort SHIFT_TOTAL_DISK_SPACE     = SHIFT_CORE_COUNT + 4;           // 10 bits
const ushort SHIFT_REMAINING_DISK_SPACE = SHIFT_TOTAL_DISK_SPACE + 10;    // 4 bits
const ushort SHIFT_BATTERY_LEVEL        = SHIFT_REMAINING_DISK_SPACE + 4; // 4 bits

const u_int  GROUP1_RECHECK_DURATION    = 30 * 60;

@interface FBAmbientDeviceInfo ()

@property (readwrite, copy) NSString *encodedDeviceInfo;

// Ephemeral data, may change during the lifetime of an app.  We collect them in different
// 'group' frequencies - group1 gets collected once every 30 minutes.

// group1
@property (readwrite, copy) NSString *carrierName;
@property (readwrite, copy) NSString *timeZoneAbbrev;

// Persistent data, but we maintain it to make rebuilding the device info as fast as possible.
@property (readwrite, copy) NSString *bundleIdentifier;
@property (readwrite, copy) NSString *longVersion;
@property (readwrite, copy) NSString *shortVersion;
@property (readwrite, copy) NSString *sysVersion;
@property (readwrite, copy) NSString *machine;
@property (readwrite, copy) NSString *language;

@end

@implementation FBAmbientDeviceInfo

// Ephemeral data, may change during the lifetime of an app.  We collect them in different
// 'group' frequencies - group1 may gets collected once every 30 minutes.

// group1
unsigned long long _remainingDiskSpaceDecile;
unsigned long long _batteryLevelDecile;

// Persistent data, but we maintain it to make rebuilding the device info as fast as possible.
unsigned long long _totalDiskSpace;
unsigned long long _totalDiskSpaceGB;
unsigned long long _uiIdiom;
unsigned long long _multitaskingSupported;
unsigned long long _coreCount;
unsigned long long _width;
unsigned long long _height;
unsigned long long _density;

long _lastGroup1CheckTime;
BOOL _isEncodingDirty = YES;

// Backing for encodedDeviceInfo property
NSString *_encodedDeviceInfo;


#pragma mark - Public Methods

+ (void)extendDictionaryWithDeviceInfo:(NSMutableDictionary *)dictionary
{
    NSString *encodedDeviceInfo = [self._singleton encodedDeviceInfo];
    [dictionary setObject:encodedDeviceInfo forKey:@"extinfo"];
}

#pragma mark - Internal Methods

+ (FBAmbientDeviceInfo *)_singleton
{
    static dispatch_once_t pred;
    static FBAmbientDeviceInfo *shared = nil;

    dispatch_once(&pred, ^{
        shared = [[FBAmbientDeviceInfo alloc] init];
    });
    return shared;
}

- (NSString *)encodedDeviceInfo
{
    @synchronized (self) {

        // As long as group1 hasn't expired, we can just return the last generated value without any synchronization
        if (_encodedDeviceInfo && ![self _isGroup1Expired]) {
            return _encodedDeviceInfo;
        }

        if (!self.bundleIdentifier) {
            // First time only
            [self _collectPersistentData];
        }

        if ([self _isGroup1Expired]) {
            [self _collectGroup1Data];
        }

        if (_isEncodingDirty) {
            self.encodedDeviceInfo = [self _generateEncoding];
            _isEncodingDirty = NO;
        }

        return _encodedDeviceInfo;
    }
}

- (void)setEncodedDeviceInfo:(NSString *)encodedDeviceInfo
{
    @synchronized (self) {
        if (![_encodedDeviceInfo isEqualToString:encodedDeviceInfo]) {
            [_encodedDeviceInfo release];
            _encodedDeviceInfo = [encodedDeviceInfo copy];
        }
    }
}

// This data need only be collected once.
- (void)_collectPersistentData
{
    // Bundle stuff
    NSBundle *mainBundle = [NSBundle mainBundle];
    self.bundleIdentifier = mainBundle.bundleIdentifier;
    self.longVersion = [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    self.shortVersion = [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

    // Locale stuff
    self.language = [[NSLocale preferredLanguages] objectAtIndex:0];

    // Device stuff
    UIDevice *device = [UIDevice currentDevice];
    self.sysVersion = device.systemVersion;
    _uiIdiom = (unsigned long long)device.userInterfaceIdiom;
    _multitaskingSupported = (unsigned long long)device.multitaskingSupported;
    _coreCount = [FBAmbientDeviceInfo _coreCount];

    UIScreen *sc = [UIScreen mainScreen];
    CGRect sr = sc.bounds;
    _width = (unsigned long long)sr.size.width;
    _height = (unsigned long long)sr.size.height;
    _density = (unsigned long long)sc.scale;

    struct utsname systemInfo;
    uname(&systemInfo);
    self.machine = @(systemInfo.machine);

    // Disk space stuff
    _totalDiskSpace = [[FBAmbientDeviceInfo _getTotalDiskSpace] unsignedLongLongValue];
    _totalDiskSpaceGB = (unsigned long long)(_totalDiskSpace / (1024 * 1024 * 1024));
}

- (BOOL)_isGroup1Expired
{
    return ([FBAppEvents unixTimeNow] - _lastGroup1CheckTime) > GROUP1_RECHECK_DURATION;
}

// This data is collected only once every GROUP1_RECHECK_DURATION.
- (void)_collectGroup1Data
{
    // Carrier
    NSString *newCarrierName = [FBAmbientDeviceInfo _getCarrier];
    if (![newCarrierName isEqualToString:self.carrierName]) {
        self.carrierName = newCarrierName;
        _isEncodingDirty = YES;
    }

    // Time zone
    NSString *newTimeZoneAbbrev = [[NSTimeZone systemTimeZone] abbreviation];
    if (![newTimeZoneAbbrev isEqualToString:self.timeZoneAbbrev]) {
        self.timeZoneAbbrev = newTimeZoneAbbrev;
        _isEncodingDirty = YES;
    }

    // Remaining disk space
    unsigned long long remainingDiskSpace = [[FBAmbientDeviceInfo _getRemainingDiskSpace] unsignedLongLongValue];
    float pctRemaining = ((float)remainingDiskSpace) / ((float)_totalDiskSpace);
    unsigned long long newRemainingDiskSpaceDecile = (unsigned long long)round(pctRemaining * 10);
    if (_remainingDiskSpaceDecile != newRemainingDiskSpaceDecile) {
        _remainingDiskSpaceDecile = newRemainingDiskSpaceDecile;
        _isEncodingDirty = YES;
    }

    // Battery Level
    unsigned long long newBatteryLevelDecile = [FBAmbientDeviceInfo _getBatteryLevelDecile];
    if (_batteryLevelDecile != newBatteryLevelDecile) {
        _batteryLevelDecile = newBatteryLevelDecile;
        _isEncodingDirty = YES;
    }

    _lastGroup1CheckTime = [FBAppEvents unixTimeNow];
}

- (NSString *)_generateEncoding
{
    // Pack small numeric values into a long long
    unsigned long long maskValue =
          (_uiIdiom & MASK_UI_IDIOM) << SHIFT_UI_IDIOM
        | (_multitaskingSupported & MASK_MULTITASKING) << SHIFT_MULTITASKING
        | (_width & MASK_WIDTH) << SHIFT_WIDTH
        | (_height & MASK_HEIGHT) << SHIFT_HEIGHT
        | (_density & MASK_DENSITY) << SHIFT_DENSITY
        | (_coreCount & MASK_CORE_COUNT) << SHIFT_CORE_COUNT
        | (_totalDiskSpaceGB & MASK_TOTAL_DISK_SPACE) << SHIFT_TOTAL_DISK_SPACE
        | (_remainingDiskSpaceDecile & MASK_REMAINING_DISK_SPACE) << SHIFT_REMAINING_DISK_SPACE
        | (_batteryLevelDecile & MASK_BATTERY_LEVEL) << SHIFT_BATTERY_LEVEL;

    NSArray *arr = @[
        @"i1", // version - starts with 'i' for iOS, we'll use 'a' for Android
        self.bundleIdentifier ?: @"",
        self.longVersion ?: @"",
        self.shortVersion ?: @"",
        self.sysVersion,
        self.machine,
        self.language,
        self.timeZoneAbbrev,
        self.carrierName,
        @(maskValue),
    ];

    return [FBUtility simpleJSONEncode:arr];
}

#pragma mark - Helper Methods

+ (ushort)_getBatteryLevelDecile
{
    UIDevice *device = [UIDevice currentDevice];

    float batteryLevel;
    if (device.isBatteryMonitoringEnabled) {
        batteryLevel = device.batteryLevel;
    } else {
        @synchronized (device) {
            [device setBatteryMonitoringEnabled:YES];
            batteryLevel = device.batteryLevel;
            [device setBatteryMonitoringEnabled:NO];
        }
    }

    int batteryLevelDecile = (int)round(batteryLevel * 10);
    if (batteryLevelDecile == -10) {
        batteryLevelDecile = 11;  // will indicate simulator, which reports a battery level of -1.
    }

    return (ushort)batteryLevelDecile;
}

+ (NSNumber *)_getTotalDiskSpace
{
    NSDictionary *attrs = [[NSFileManager defaultManager]
                           attributesOfFileSystemForPath:NSHomeDirectory()
                           error:nil];
    return [attrs objectForKey:NSFileSystemSize];
}

+ (NSNumber *)_getRemainingDiskSpace
{
    NSDictionary *attrs = [[NSFileManager defaultManager]
                           attributesOfFileSystemForPath:NSHomeDirectory()
                           error:nil];
    return [attrs objectForKey:NSFileSystemFreeSize];
}

+ (uint)_coreCount
{
    return [FBAmbientDeviceInfo _readSysCtlUInt:CTL_HW type:HW_AVAILCPU];
}

+ (uint)_readSysCtlUInt:(int)ctl type:(int)type
{
    int mib[2] = {ctl, type};
    uint value;
    size_t size = sizeof value;
    if (0 != sysctl(mib, ARRAY_COUNT(mib), &value, &size, NULL, 0)) {
        return 0;
    }
    return value;
}

+ (NSString *)_getCarrier
{
    // Dynamically load class for this so calling app doesn't need to link framework in.
    Class CTTelephonyNetworkInfoClass = [FBDynamicFrameworkLoader loadClass:@"CTTelephonyNetworkInfo" withFramework:@"CoreTelephony"];
    CTTelephonyNetworkInfo *networkInfo = [[[CTTelephonyNetworkInfoClass alloc] init] autorelease];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    return [carrier carrierName] ?: @"NoCarrier";
}

@end
