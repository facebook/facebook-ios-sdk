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

#import "FBSDKSettings+Internal.h"

static NSString * const FBSDKAppIdKey = @"appID";
static NSString * const FBSDKOsVersionKey = @"device_os_version";
static NSString * const FBSDKDeviceModelKey = @"device_model";

@interface FBSDKMonitorEntry ()

@property (nonatomic, readonly) NSString *appID;
@property (nonatomic, readonly) NSString *systemVersion;
@property (nonatomic, readonly) NSString *deviceModel;

@end

@implementation FBSDKMonitorEntry

- (instancetype)init
{
  if (self = [super init]) {
    // Base class FBSDKMonitorEntry should not be directly initialized
    if ([self isMemberOfClass:[FBSDKMonitorEntry class]]) {
      return nil;
    }

    _appID = [FBSDKSettings appID];
    _systemVersion = [[UIDevice currentDevice] systemVersion];
    _deviceModel = [FBSDKMonitorEntry deviceModel];
  }

  return self;
}

- (NSDictionary *)dictionaryRepresentation
{
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

  if (self.appID) {
    [dictionary setObject:self.appID forKey:FBSDKAppIdKey];
  }

  [dictionary setObject:UIDevice.currentDevice.systemVersion forKey:FBSDKOsVersionKey];
  [dictionary setObject:[FBSDKMonitorEntry deviceModel] forKey:FBSDKDeviceModelKey];

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
  if (self.appID) {
    [encoder encodeObject:self.appID forKey:FBSDKAppIdKey];
  }

  [encoder encodeObject:UIDevice.currentDevice.systemVersion forKey:FBSDKOsVersionKey];
  [encoder encodeObject:[FBSDKMonitorEntry deviceModel] forKey:FBSDKDeviceModelKey];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)decoder
{
  _appID = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDKAppIdKey];
  _systemVersion = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDKOsVersionKey];
  _deviceModel = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDKDeviceModelKey];

  return self;
}

@end
