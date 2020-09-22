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

#import "FBSDKAppEventsConfigurationFixtures.h"

#import "FBSDKAppEventsConfiguration.h"

@interface FBSDKAppEventsConfiguration (Testing)

+ (FBSDKAppEventsConfiguration *)defaultConfiguration;

- (instancetype)initWithDefaultATEStatus:(FBSDKAdvertisingTrackingStatus)defaultATEStatus
           advertiserIDCollectionEnabled:(BOOL)advertiserIDCollectionEnabled
                  eventCollectionEnabled:(BOOL)eventCollectionEnabled;

@end

@implementation FBSDKAppEventsConfigurationFixtures

+ (FBSDKAppEventsConfiguration *)defaultConfig;
{
  return [FBSDKAppEventsConfiguration defaultConfiguration];
}

+ (FBSDKAppEventsConfiguration *)configWithDictionary:(NSDictionary *)dict
{
  FBSDKAppEventsConfiguration *defaultConfig = [FBSDKAppEventsConfiguration defaultConfiguration];
  FBSDKAdvertisingTrackingStatus defaultATEStatus = defaultConfig.defaultATEStatus;
  if (dict[@"default_ate_status"]) {
    defaultATEStatus = [dict[@"default_ate_status"] intValue];
  }
  BOOL advertiserIDCollectionEnabled = defaultConfig.advertiserIDCollectionEnabled;
  if (dict[@"advertiser_id_collection_enabled"]) {
    advertiserIDCollectionEnabled = [dict[@"advertiser_id_collection_enabled"] boolValue];
  }
  BOOL eventCollectionEnabled = defaultConfig.eventCollectionEnabled;
  if (dict[@"event_collection_enabled"]) {
    eventCollectionEnabled = [dict[@"event_collection_enabled"] boolValue];
  }
  return [[FBSDKAppEventsConfiguration alloc]
          initWithDefaultATEStatus:defaultATEStatus
          advertiserIDCollectionEnabled:advertiserIDCollectionEnabled
          eventCollectionEnabled:eventCollectionEnabled];
}

@end
