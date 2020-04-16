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

#import "FBSDKCoreKit+Internal.h"

#import "FBSDKMonitoringConfiguration.h"

static NSString *defaultRateKey = @"default";
static NSString *sampleRatesKey = @"sample_rates";
static NSString *sampleRateNameKey = @"key";
static NSString *sampleRateValueKey = @"value";

@implementation FBSDKMonitoringConfiguration {
  NSDictionary<NSString *, NSNumber *> *_sampleRates;
}

typedef NSDictionary<NSString *, id> RemoteSampleRates;
typedef NSDictionary<NSString *, NSNumber *> SampleRates;

- (int)defaultSamplingRate
{
  return [_sampleRates[defaultRateKey] intValue];
}

+ (FBSDKMonitoringConfiguration *)defaultConfiguration
{
  return [[FBSDKMonitoringConfiguration alloc] initWithDictionary:@{}];
}

+ (instancetype)fromDictionary:(NSDictionary *)dictionary
{
  return [[FBSDKMonitoringConfiguration alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
  if (self = [super init]) {
    NSMutableDictionary *sampleRates = [NSMutableDictionary dictionary];
    NSArray<RemoteSampleRates *> *remoteSampleRates = dictionary[sampleRatesKey];

    for (RemoteSampleRates *ratePair in remoteSampleRates) {
      NSString *key = ratePair[sampleRateNameKey];
      NSNumber *value = ratePair[sampleRateValueKey];

      if ([value isKindOfClass:[NSNumber class]] &&
          value.intValue > 0) {
        [FBSDKBasicUtility dictionary:sampleRates setObject:value forKey:key];
      }
    }

    _sampleRates = [sampleRates copy];
  }

  return self;
}

- (int)sampleRateForEntry:(nonnull id<FBSDKMonitorEntry>)entry
{
  return [_sampleRates objectForKey:entry.name].intValue ?: self.defaultSamplingRate;
}

- (void)encodeWithCoder:(nonnull NSCoder *)encoder {
  [encoder encodeObject:_sampleRates forKey:sampleRatesKey];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)decoder {
  _sampleRates = [decoder decodeObjectOfClass:[SampleRates class] forKey:sampleRatesKey];
  return self;
}

// Private getter for cleaner tests
- (SampleRates *)sampleRates
{
  return _sampleRates;
}

@end
