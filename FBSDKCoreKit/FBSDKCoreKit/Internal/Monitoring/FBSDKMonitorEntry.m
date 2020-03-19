// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FBSDKMonitorEntry.h"

#import <sys/utsname.h>

#import "FBSDKCoreKit+Internal.h"

static NSString * const FBSDKAppIdKey = @"appID";
static NSString * const FBSDKOsVersionKey = @"device_os_version";
static NSString * const FBSDKDeviceModelKey = @"device_model";

@implementation FBSDKMonitorEntry {
  NSString * _appID;
  NSString * _systemVersion;
  NSString * _deviceModel;
}

- (instancetype)init
{
  if (self = [super init]) {
    // Base class FBSDKMonitorEntry should not be directly initialized
    if ([self isMemberOfClass:[FBSDKMonitorEntry class]]) {
      return nil;
    }

    _appID = [[FBSDKSettings appID] copy];
    _systemVersion = [[UIDevice currentDevice] systemVersion];
    _deviceModel = [FBSDKMonitorEntry deviceModel];
  }

  return self;
}

- (NSDictionary *)dictionaryRepresentation
{
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

  [FBSDKBasicUtility dictionary:dictionary setObject:_appID forKey:FBSDKAppIdKey];
  [FBSDKBasicUtility dictionary:dictionary setObject:_systemVersion forKey:FBSDKOsVersionKey];
  [FBSDKBasicUtility dictionary:dictionary setObject:_deviceModel forKey:FBSDKDeviceModelKey];

  return dictionary;
}

+ (NSString * _Nonnull)deviceModel
{
  struct utsname systemInfo;
  uname(&systemInfo);

  return [NSString stringWithCString:systemInfo.machine
                            encoding:NSUTF8StringEncoding];
}

- (void)encodeWithCoder:(nonnull NSCoder *)encoder {
  if (_appID) {
    [encoder encodeObject:_appID forKey:FBSDKAppIdKey];
  }

  if (_systemVersion) {
    [encoder encodeObject:_systemVersion forKey:FBSDKOsVersionKey];
  }

  if (_deviceModel) {
    [encoder encodeObject:_deviceModel forKey:FBSDKDeviceModelKey];
  }
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)decoder
{
  _appID = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDKAppIdKey];
  _systemVersion = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDKOsVersionKey];
  _deviceModel = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDKDeviceModelKey];

  return self;
}

@end
