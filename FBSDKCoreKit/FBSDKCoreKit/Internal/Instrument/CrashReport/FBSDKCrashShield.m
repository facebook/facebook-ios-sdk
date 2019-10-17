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

#import "FBSDKCrashShield.h"

#import "FBSDKFeatureManager.h"

@implementation FBSDKCrashShield

static NSDictionary<NSString *, NSArray<NSString *> *> *_featureMapping;

+ (void)initialize
{
  if (self == [FBSDKCrashShield class]) {
    _featureMapping =
    @{
      @"AAM" : @[
          @"FBSDKMetadataIndexer",
      ],
      @"CodelessEvents" : @[
          @"FBSDKCodelessIndexer",
          @"FBSDKEventBinding",
          @"FBSDKEventBindingManager",
          @"FBSDKViewHierarchy",
          @"FBSDKCodelessPathComponent",
          @"FBSDKCodelessParameterComponent",
      ],
      @"RestrictiveDataFiltering" : @[
          @"FBSDKRestrictiveDataFilterManager",
      ],
      @"ErrorReport" : @[
          @"FBSDKErrorReport",
      ],
    };
  }
}

+ (void)analyze:(NSArray<NSDictionary<NSString *, id> *> *)crashLogs
{
  for (NSDictionary<NSString *, id> *crashLog in crashLogs) {
    NSArray<NSString *> *callstack = crashLog[@"callstack"];
    NSString *featureName = [self getFeature:callstack];
      if (featureName) {
        [FBSDKFeatureManager disableFeature:featureName];
      }
  }
}

+ (nullable NSString *)getFeature:(NSArray<NSString *> *)callstack
{
  for (NSString *featureName in _featureMapping) {
    NSArray<NSString *> *classArray = [_featureMapping objectForKey:featureName];
    for (NSString *entry in callstack) {
      NSString *className = [self getClassName:entry];
      if ([classArray containsObject:className]) {
        return featureName;
      }
    }
  }
  return nil;
}

+ (nullable NSString *)getClassName:(NSString *)entry
{
  NSArray<NSString *> *items = [entry componentsSeparatedByString:@" "];
  NSString *className = nil;
  // parse class name only from an entry in format "-[className functionName]+offset"
  // or "+[className functionName]+offset"
  if (items.count > 0 && ([items[0] hasPrefix:@"+["] || [items[0] hasPrefix:@"-["])) {
    className = [items[0] substringFromIndex:2];
  }
  return className;
}

@end
