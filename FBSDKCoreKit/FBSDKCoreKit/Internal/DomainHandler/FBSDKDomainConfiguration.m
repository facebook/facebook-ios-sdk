/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKDomainConfiguration.h"
#import "FBSDKDomainConfiguration+Internal.h"

#define DOMAIN_CONFIGURATION_DOMAIN_INFO @"domainInfo"
#define DOMAIN_CONFIGURATION_TIMESTAMP_KEY @"timestamp"

NSString *const kEndpoint1URLPrefix = @"ep1";
NSString *const kEndpoint2URLPrefix = @"ep2";

// Increase this value when adding new fields and previous cached configurations should be
// treated as stale.
const NSInteger FBSDKDomainConfigurationVersion = 1;

@interface FBSDKDomainConfiguration ()
@end

@implementation FBSDKDomainConfiguration

static NSDictionary<NSString *, NSDictionary<NSString *, id> *> *defaultDomainInfo = nil;

- (instancetype)initWithTimestamp:(nullable NSDate *)timestamp
                       domainInfo:(nullable NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)domainInfo
{
  if ((self = [super init])) {
    _timestamp = timestamp;
    _domainInfo = domainInfo;
    _version = FBSDKDomainConfigurationVersion;
  }
  return self;
}

+ (void)setDefaultDomainInfo
{
  defaultDomainInfo = @{
    @"activities" : @{
      @"att_opt_in_domain_prefix": kEndpoint1URLPrefix,
      @"att_opt_out_domain_prefix": kEndpoint2URLPrefix
    },
    @"custom_audience_third_party_id" : @{
      @"att_opt_in_domain_prefix": kEndpoint1URLPrefix,
      @"att_opt_out_domain_prefix": kEndpoint1URLPrefix
    },
    @"app_indexing_session" : @{
      @"att_opt_in_domain_prefix": kEndpoint1URLPrefix,
      @"att_opt_out_domain_prefix": kEndpoint1URLPrefix
    },
    @"default_config" : @{
      @"default_domain_prefix": kEndpoint2URLPrefix,
      @"default_alternative_domain_prefix": kEndpoint1URLPrefix,
      @"enable_for_early_versions": @NO
    }
  };
}

+ (FBSDKDomainConfiguration *)defaultDomainConfiguration
{
  // Use a default configuration while we do not have a configuration back from the server.
  static FBSDKDomainConfiguration *_defaultDomainConfiguration = nil;

  _defaultDomainConfiguration = [[FBSDKDomainConfiguration alloc] initWithTimestamp:nil
                                                                         domainInfo:defaultDomainInfo];
  return _defaultDomainConfiguration;
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  NSDate *timestamp = [decoder decodeObjectOfClass:NSDate.class forKey:DOMAIN_CONFIGURATION_TIMESTAMP_KEY];
  NSSet<Class> *domainInfoClasses = [[NSSet alloc] initWithObjects:
                                     [NSDictionary<NSString *, id> class],
                                     NSString.class,
                                     NSNumber.class,
                                     nil];

  NSDictionary<NSString *, id> *domainInfo = [decoder decodeObjectOfClasses:domainInfoClasses
                                                                     forKey:DOMAIN_CONFIGURATION_DOMAIN_INFO];
  FBSDKDomainConfiguration *configuration = [self initWithTimestamp:timestamp
                                                         domainInfo:domainInfo];

  return configuration;
}


- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_domainInfo forKey:DOMAIN_CONFIGURATION_DOMAIN_INFO];
  [encoder encodeObject:_timestamp forKey:DOMAIN_CONFIGURATION_TIMESTAMP_KEY];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
  return self;
}

#if DEBUG

+ (void)resetDefaultDomainInfo
{
  defaultDomainInfo = nil;
}

#endif

@end
