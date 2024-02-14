/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKDomainHandler.h"
#import "FBSDKDomainConfigurationProviding.h"
#import "FBSDKDomainConfigurationManager.h"
#import "FBSDKAuthenticationToken.h"
#import "FBSDKDomainConfiguration+Internal.h"
#import "FBSDKGraphRequest+Internal.h"

@interface FBSDKDomainHandler ()

@property (nullable, nonatomic) id<FBSDKDomainConfigurationProviding> domainConfigurationProvider;

@end

// Domain configuration keys
static NSString *const kAttOptInDomainPrefixKey = @"att_opt_in_domain_prefix";
static NSString *const kAttOptOutDomainPrefixKey = @"att_opt_out_domain_prefix";
static NSString *const kDefaultDomainConfigKey = @"default_config";
static NSString *const kDefaultDomainPrefixKey = @"default_domain_prefix";
static NSString *const kDefaultAlternativeDomainPrefixKey = @"default_alternative_domain_prefix";
static NSString *const kEnableForEarlierVersionsKey = @"enable_for_early_versions";

// Domain prefixes
static NSString *const kEndpoint3URLPrefix = @"graph";
static NSString *const kVideoURLPrefix = @"graph-video";

@implementation FBSDKDomainHandler

- (instancetype)init
{
  return [super init];
}

+ (instancetype)sharedInstance
{
  static FBSDKDomainHandler *instance = nil;
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
    instance = [FBSDKDomainHandler new];
  });
  return instance;
}

- (void)configureWithGraphRequestFactory:(id<FBSDKDomainConfigurationProviding>)domainConfigurationProvider
                                settings:(id<FBSDKSettings>)settings
                               dataStore:(id<FBSDKDataPersisting>)dataStore
                     graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
           graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
{
  self.domainConfigurationProvider = domainConfigurationProvider;
  [self.domainConfigurationProvider configureWithSettings:settings
                                                dataStore:dataStore
                                      graphRequestFactory:graphRequestFactory
                            graphRequestConnectionFactory:graphRequestConnectionFactory
  ];
}

- (void)loadDomainConfigurationWithCompletionBlock:(nullable FBSDKDomainConfigurationBlock)completionBlock
{
  [self.domainConfigurationProvider loadDomainConfigurationWithCompletionBlock:completionBlock];
}

+ (BOOL)isAuthenticatedForGamingDomain
{
  return [FBSDKAuthenticationToken.currentAuthenticationToken respondsToSelector:@selector(graphDomain)]
  && [FBSDKAuthenticationToken.currentAuthenticationToken.graphDomain isEqualToString:@"gaming"];
}

- (BOOL)isGraphVideoRequest:(id<FBSDKGraphRequest>)request
{
  NSString *graphPath = [self.class getCleanedGraphPathFromRequest:request];
  if ([request.HTTPMethod.uppercaseString isEqualToString:@"POST"] && [graphPath hasSuffix:@"/videos"]) {
    NSArray<NSString *> *components = [graphPath componentsSeparatedByString:@"/"];
    if (components.count == 2) {
      return YES;
    }
  }
  return NO;
}

- (NSString *)getDefaultDomainPrefix:(BOOL)useAlternativeDefaultDomainPrefix
{
  NSDictionary *domainConfig = [self.domainConfigurationProvider cachedDomainConfiguration].domainInfo;
  NSString *defaultKeyToUse = kDefaultDomainPrefixKey;
  if (useAlternativeDefaultDomainPrefix) {
    defaultKeyToUse = kDefaultAlternativeDomainPrefixKey;
  }
  NSString *prefix = [[domainConfig objectForKey:kDefaultDomainConfigKey] objectForKey:defaultKeyToUse];
  if (prefix) {
    return [NSString stringWithFormat:@"%@.", prefix];
  }
  return [NSString stringWithFormat:@"%@.", kEndpoint2URLPrefix];
}

- (NSString *)getAttOptInDomainPrefixForEndpoint:(NSString *)endpoint
               useAlternativeDefaultDomainPrefix:(BOOL)useAlternativeDefaultDomainPrefix
{
  NSDictionary *domainConfig = [self.domainConfigurationProvider cachedDomainConfiguration].domainInfo;
  NSString *prefix = [[domainConfig objectForKey:endpoint] objectForKey:kAttOptInDomainPrefixKey];
  if (prefix) {
    return [NSString stringWithFormat:@"%@.", prefix];
  }
  return [self getDefaultDomainPrefix:useAlternativeDefaultDomainPrefix];
}

- (NSString *)getAttOptOutDomainPrefixForEndpoint:(NSString *)endpoint
                useAlternativeDefaultDomainPrefix:(BOOL)useAlternativeDefaultDomainPrefix
{
  NSDictionary *domainConfig = [self.domainConfigurationProvider cachedDomainConfiguration].domainInfo;
  NSString *prefix = [[domainConfig objectForKey:endpoint] objectForKey:kAttOptOutDomainPrefixKey];
  if (prefix) {
    return [NSString stringWithFormat:@"%@.", prefix];
  }
  return [self getDefaultDomainPrefix:useAlternativeDefaultDomainPrefix];
}

- (nullable NSString *)getATTScopeEndpointForGraphPath:(NSString *)graphPath
{
  NSDictionary *domainConfig = [self.domainConfigurationProvider cachedDomainConfiguration].domainInfo;
  NSArray<NSString *> *keys = [domainConfig allKeys];
  for (NSString *key in keys) {
    if ([graphPath hasSuffix:key]) {
      return key;
    }
  }
  return nil;
}

- (BOOL)isDomainHandlingEnabled
{
  if (@available(iOS 17.0, *)) {
    return YES;
  }
  NSDictionary *domainConfig = [self.domainConfigurationProvider cachedDomainConfiguration].domainInfo;
  id enableForEarlierVersions = [[domainConfig objectForKey:kDefaultDomainConfigKey] objectForKey:kEnableForEarlierVersionsKey];
  BOOL shouldEnableForEarlierVersions = enableForEarlierVersions ? [enableForEarlierVersions boolValue] : NO;
  BOOL isIOS145Available = NO;
  if (@available(iOS 14.5, *)) {
    isIOS145Available = YES;
  }
  return (isIOS145Available && shouldEnableForEarlierVersions);
}

+ (NSString *)getCleanedGraphPathFromRequest:(id<FBSDKGraphRequest>)request
{
  NSString *graphPath = request.graphPath.lowercaseString;
  return [graphPath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
}

- (NSString *)getURLPrefixForSingleRequest:(id<FBSDKGraphRequest>)request
               isAdvertiserTrackingEnabled:(BOOL)isATTOptIn
{
  // Special case: a graph request for fetching the domain config must use ep2. prefix
  if (@available(iOS 14.5, *)) {
    if ([FBSDKGraphRequest isForFetchingDomainConfiguration:request]) {
      return [NSString stringWithFormat:@"%@.", kEndpoint2URLPrefix];
    }
  }
  // Special case: a graph post to <id>/videos must use graph-video. prefix
  if ([self isGraphVideoRequest:request]) {
    return [NSString stringWithFormat:@"%@.", kVideoURLPrefix];
  }
  // Special case: a graph request for gaming domain will always use graph. prefix
  if ([FBSDKDomainHandler isAuthenticatedForGamingDomain]) {
    return [NSString stringWithFormat:@"%@.", kEndpoint3URLPrefix];
  }
  if ([self isDomainHandlingEnabled]) {
    NSString *graphPath = [self.class getCleanedGraphPathFromRequest:request];
    // Special case: a graph request to the /activities endpoint that is not for app events will always use default domain prefix
    if ([graphPath hasSuffix:@"activities"] && !request.forAppEvents) {
      return [self getDefaultDomainPrefix:request.useAlternativeDefaultDomainPrefix];
    }
    NSString *attScopeEndpoint = [self getATTScopeEndpointForGraphPath:graphPath];
    if (attScopeEndpoint) {
      if (isATTOptIn) {
        return [self getAttOptInDomainPrefixForEndpoint:attScopeEndpoint
                      useAlternativeDefaultDomainPrefix:request.useAlternativeDefaultDomainPrefix];
      } else {
        return [self getAttOptOutDomainPrefixForEndpoint:attScopeEndpoint
                       useAlternativeDefaultDomainPrefix:request.useAlternativeDefaultDomainPrefix];
      }
    }
    return [self getDefaultDomainPrefix:request.useAlternativeDefaultDomainPrefix];
  } else {
    // If domain handling is not enabled, we always use graph
    return [NSString stringWithFormat:@"%@.", kEndpoint3URLPrefix];
  }
}

- (NSString *)getURLPrefixForBatchRequest:(NSArray<FBSDKGraphRequestMetadata *> *)requestsMetaData
              isAdvertiserTrackingEnabled:(BOOL)isATTOptIn
{
  // Special case: a graph request for gaming domain will always use graph. prefix
  if ([FBSDKDomainHandler isAuthenticatedForGamingDomain]) {
    return [NSString stringWithFormat:@"%@.", kEndpoint3URLPrefix];
  }
  
  if ([self isDomainHandlingEnabled]) {
    BOOL useAlternativeDefaultDomainPrefix = YES;
    for (FBSDKGraphRequestMetadata *metadata in requestsMetaData) {
      // If any request does not use the alternative, the batch does not use the alternative
      if (!metadata.request.useAlternativeDefaultDomainPrefix) {
        useAlternativeDefaultDomainPrefix = NO;
      }
      NSString *graphPath = [self.class getCleanedGraphPathFromRequest:metadata.request];
      // Special case: a graph request to the /activities endpoint that is not for app events will always use default domain prefix
      if ([graphPath hasSuffix:@"activities"] && !metadata.request.forAppEvents) {
        continue;
      }
      NSString *attScopeEndpoint = [self getATTScopeEndpointForGraphPath:graphPath];
      if (isATTOptIn && attScopeEndpoint) {
        return [self getAttOptInDomainPrefixForEndpoint:attScopeEndpoint
                      useAlternativeDefaultDomainPrefix:metadata.request.useAlternativeDefaultDomainPrefix];
      }
    }
    return [self getDefaultDomainPrefix:useAlternativeDefaultDomainPrefix];
  } else {
    // If domain handling is not enabled, we always use graph
    return [NSString stringWithFormat:@"%@.", kEndpoint3URLPrefix];
  }
}

@end
