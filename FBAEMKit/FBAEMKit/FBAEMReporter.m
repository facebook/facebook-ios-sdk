/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBAEMReporter.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import <FBAEMKit/FBAEMKit-Swift.h>

#import "FBAEMAdvertiserRuleFactory.h"
#import "FBAEMInvocation.h"
#import "FBAEMNetworker.h"
#import "FBAEMRule.h"
#import "FBAEMUtility.h"

#define FB_AEM_CONFIG_TIME_OUT 86400
#define FB_AEM_DELAY           3

typedef void (^FBAEMReporterBlock)(NSError *);

static NSString *const BUSINESS_ID_KEY = @"advertiser_id";
static NSString *const BUSINESS_IDS_KEY = @"advertiser_ids";
static NSString *const AL_APPLINK_DATA_KEY = @"al_applink_data";
static NSString *const CAMPAIGN_ID_KEY = @"campaign_id";
static NSString *const CONVERSION_DATA_KEY = @"conversion_data";
static NSString *const CONSUMPTION_HOUR_KEY = @"consumption_hour";
static NSString *const TOKEN_KEY = @"token";
static NSString *const HMAC_KEY = @"hmac";
static NSString *const CONFIG_ID_KEY = @"config_id";
static NSString *const DELAY_FLOW_KEY = @"delay_flow";
static NSString *const IS_CONVERSION_FILTERING_KEY = @"is_conversion_filtering";

static NSString *const FB_CONTENT_IDS_KEY = @"fb_content_ids";
static NSString *const CATALOG_ID_KEY = @"catalog_id";

static NSString *const FBAEMConfigurationKey = @"com.facebook.sdk:FBSDKAEMConfiguration";
static NSString *const FBAEMReporterKey = @"com.facebook.sdk:FBSDKAEMReporter";
static NSString *const FBAEMMINAggregationRequestTimestampKey = @"com.facebook.sdk:FBAEMMinAggregationRequestTimestamp";
static NSString *const FBAEMReporterFileName = @"FBSDKAEMReportData.report";
static NSString *const FBAEMConfigFileName = @"FBSDKAEMReportData.config";
static NSString *const FBAEMHTTPMethodGET = @"GET";
static NSString *const FBAEMHTTPMethodPOST = @"POST";

static BOOL g_isAEMReportEnabled = NO;
static BOOL g_isLoadingConfiguration = NO;
static BOOL g_isConversionFilteringEnabled = NO;
static BOOL g_isCatalogMatchingEnabled = NO;
static dispatch_queue_t g_serialQueue;
static NSString *g_reportFile;
static NSString *g_configFile;
static NSMutableDictionary<NSString *, NSMutableArray<FBAEMConfiguration *> *> *g_configs;
static NSMutableArray<FBAEMInvocation *> *g_invocations;
static NSDate *g_configRefreshTimestamp;
static NSDate *g_minAggregationRequestTimestamp;
static NSMutableArray<FBAEMReporterBlock> *g_completionBlocks;

@interface FBAEMReporter ()

@property (class, nullable, nonatomic) id<FBAEMNetworking> networker;
@property (class, nullable, nonatomic) NSString *appID;
@property (class, nullable, nonatomic) NSString *analyticsAppID;
@property (class, nullable, nonatomic) id<FBSKAdNetworkReporting> reporter;
@property (class, nullable, nonatomic) id<FBSDKDataPersisting> store;

@end

@implementation FBAEMReporter

static char *const dispatchQueueLabel = "com.facebook.appevents.AEM.FBAEMReporter";

+ (void)configureWithNetworker:(nullable id<FBAEMNetworking>)networker
                         appID:(nullable NSString *)appID
{
  [self configureWithNetworker:networker appID:appID reporter:nil];
}

+ (void)configureWithNetworker:(nullable id<FBAEMNetworking>)networker
                         appID:(nullable NSString *)appID
                      reporter:(nullable id<FBSKAdNetworkReporting>)reporter
{
  [self configureWithNetworker:networker
                         appID:appID
                      reporter:reporter
                analyticsAppID:nil];
}

+ (void)configureWithNetworker:(nullable id<FBAEMNetworking>)networker
                         appID:(nullable NSString *)appID
                      reporter:(nullable id<FBSKAdNetworkReporting>)reporter
                analyticsAppID:(nullable NSString *)analyticsAppID
{
  [self configureWithNetworker:networker
                         appID:appID
                      reporter:reporter
                analyticsAppID:analyticsAppID
                         store:NSUserDefaults.standardUserDefaults];
}

+ (void)configureWithNetworker:(nullable id<FBAEMNetworking>)networker
                         appID:(nullable NSString *)appID
                      reporter:(nullable id<FBSKAdNetworkReporting>)reporter
                analyticsAppID:(nullable NSString *)analyticsAppID
                         store:(nullable id<FBSDKDataPersisting>)store
{
  if (self == FBAEMReporter.class) {
    self.networker = networker;
    self.appID = appID;
    self.reporter = reporter;
    self.analyticsAppID = analyticsAppID;
    self.store = store;
  }
}

static id<FBAEMNetworking> _networker;

+ (nullable id<FBAEMNetworking>)networker
{
  return _networker;
}

+ (void)setNetworker:(nullable id<FBAEMNetworking>)networker
{
  _networker = networker;
}

static NSString *_appID;

+ (nullable NSString *)appID
{
  return _appID;
}

+ (void)setAppID:(nullable NSString *)appID
{
  _appID = appID;
}

static NSString *_analyticsAppID;

+ (nullable NSString *)analyticsAppID
{
  return _analyticsAppID;
}

+ (void)setAnalyticsAppID:(nullable NSString *)analyticsAppID
{
  _analyticsAppID = analyticsAppID;
}

static id<FBSKAdNetworkReporting> _reporter;

+ (nullable id<FBSKAdNetworkReporting>)reporter
{
  return _reporter;
}

+ (void)setReporter:(nullable id<FBSKAdNetworkReporting>)reporter
{
  _reporter = reporter;
}

static id<FBSDKDataPersisting> _store;

+ (nullable id<FBSDKDataPersisting>)store
{
  return _store;
}

+ (void)setStore:(nullable id<FBSDKDataPersisting>)store
{
  _store = store;
}

+ (void)enable
{
  if (@available(iOS 14.0, *)) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      [FBAEMConfiguration configureWithRuleProvider:[FBAEMAdvertiserRuleFactory new]];
      g_reportFile = [FBSDKBasicUtility persistenceFilePath:FBAEMReporterFileName];
      g_configFile = [FBSDKBasicUtility persistenceFilePath:FBAEMConfigFileName];
      g_completionBlocks = [NSMutableArray new];
      if (!g_serialQueue) {
        g_serialQueue = dispatch_queue_create(dispatchQueueLabel, DISPATCH_QUEUE_SERIAL);
      }
      [self dispatchOnQueue:g_serialQueue delay:0 block:^() {
        g_minAggregationRequestTimestamp = [self _loadMinAggregationRequestTimestamp];
        g_configs = [self _loadConfigs];
        g_invocations = [self _loadReportData];
      }];
      [self _loadConfigurationWithRefreshForced:NO block:^(NSError *error) {
        if (error) {
          return;
        }
        [self _sendAggregationRequest];
        [self _clearCache];
      }];
      // If developers forget to call configureWithNetworker:appID:
      // or pass nil for networker,
      // we use default networker in FBAEMKit
      if (!self.networker) {
        FBAEMNetworker *networker = [FBAEMNetworker new];
        [networker setUserAgentSuffix:self.analyticsAppID];
        self.networker = networker;
      }
      // If developers forget to call configureWithNetworker:appID:,
      // we will look up app id in plist file, key is FacebookAppID
      if (!self.appID) {
        self.appID = [FBAEMSettings appID];
      }
      // If appId is still nil, we don't enable AEM and throw warning here
      if (!self.appID) {
        NSLog(@"App ID is not set up correctly, please call configureWithNetworker:appID: and pass correct FB app ID OR add FacebookAppID in the info.plist file");
        return;
      }
      g_isAEMReportEnabled = YES;
    });
  }
}

+ (void)setConversionFilteringEnabled:(BOOL)enabled
{
  g_isConversionFilteringEnabled = enabled;
}

+ (void)setCatalogMatchingEnabled:(BOOL)enabled
{
  g_isCatalogMatchingEnabled = enabled;
}

+ (void)handleURL:(NSURL *)url
{
  if (!g_isAEMReportEnabled) {
    return;
  }

  FBAEMInvocation *invocation = [self parseURL:url];
  if (!invocation) {
    return;
  }
  if (invocation.isTestMode) {
    [self _sendDebuggingRequest:invocation];
    return;
  }

  [self _loadConfigurationWithRefreshForced:YES block:nil];
  [self _appendAndSaveInvocation:invocation];
}

+ (nullable FBAEMInvocation *)parseURL:(NSURL *)url
{
  if (!url) {
    return nil;
  }

  NSDictionary<NSString *, NSString *> *params = [FBSDKBasicUtility dictionaryWithQueryString:url.query];
  NSString *applinkDataString = params[AL_APPLINK_DATA_KEY];
  if (!applinkDataString) {
    return nil;
  }

  NSDictionary<id, id> *applinkData = [FBSDKTypeUtility dictionaryValue:[FBSDKBasicUtility objectForJSONString:applinkDataString error:NULL]];
  if (!applinkData) {
    return nil;
  }

  return [FBAEMInvocation invocationWithAppLinkData:applinkData];
}

+ (void)recordAndUpdateEvent:(NSString *)event
                    currency:(nullable NSString *)currency
                       value:(nullable NSNumber *)value
                  parameters:(nullable NSDictionary<NSString *, id> *)parameters
{
  if (@available(iOS 14.0, *)) {
    if (!g_isAEMReportEnabled || 0 == event.length) {
      return;
    }
    [self _loadConfigurationWithRefreshForced:NO block:^(NSError *error) {
      if (0 == g_configs.count || 0 == g_invocations.count) {
        return;
      }

      FBAEMInvocation *attributedInvocation = [self _attributedInvocation:g_invocations Event:event currency:currency value:value parameters:parameters configs:g_configs];
      if (attributedInvocation) {
        // We will report conversion in catalog level if
        // 1. conversion filtering and catalog matching are enabled
        // 2. invocation has catalog id
        // 3. event is optimized
        // 4. event's content id belongs to the catalog
        if ([self _shouldReportConversionInCatalogLevel:attributedInvocation event:event]) {
          NSString *contentID = [FBAEMUtility.sharedUtility getContentID:parameters];
          [self _loadCatalogOptimizationWithInvocation:attributedInvocation contentID:contentID block:^() {
            [self _updateAttributedInvocation:attributedInvocation
                                        event:event
                                     currency:currency value:value
                                   parameters:parameters
                          shouldBoostPriority:YES];
          }];
        } else {
          [self _updateAttributedInvocation:attributedInvocation
                                      event:event
                                   currency:currency
                                      value:value
                                 parameters:parameters
                        shouldBoostPriority:g_isConversionFilteringEnabled];
        }
      }
    }];
  }
}

+ (void)_updateAttributedInvocation:(FBAEMInvocation *)invocation
                              event:(NSString *)event
                           currency:(nullable NSString *)currency
                              value:(nullable NSNumber *)value
                         parameters:(nullable NSDictionary<NSString *, id> *)parameters
                shouldBoostPriority:(BOOL)shouldBoostPriority
{
  [invocation attributeEvent:event
                    currency:currency
                       value:value
                  parameters:parameters
                     configs:g_configs
           shouldUpdateCache:YES];
  if ([invocation updateConversionValueWithConfigs:g_configs
                                             event:event
                               shouldBoostPriority:shouldBoostPriority]) {
    [self _sendAggregationRequest];
  }
  [self _saveReportData];
}

+ (nullable FBAEMInvocation *)_attributedInvocation:(NSArray<FBAEMInvocation *> *)invocations
                                              Event:(NSString *)event
                                           currency:(nullable NSString *)currency
                                              value:(nullable NSNumber *)value
                                         parameters:(nullable NSDictionary<NSString *, id> *)parameters
                                            configs:(NSDictionary<NSString *, NSMutableArray<FBAEMConfiguration *> *> *)configs
{
  BOOL isGeneralInvocationVisited = NO;
  FBAEMInvocation *attributedInvocation = nil;
  for (FBAEMInvocation *invocation in [invocations reverseObjectEnumerator]) {
    if ([self _isDoubleCounting:invocation event:event]) {
      break;
    }
    if (!invocation.businessID && isGeneralInvocationVisited) {
      continue;
    }

    if ([invocation attributeEvent:event currency:currency value:value parameters:parameters configs:configs shouldUpdateCache:NO]) {
      attributedInvocation = invocation;
      break;
    }
    if (!invocation.businessID) {
      isGeneralInvocationVisited = YES;
    }
  }
  return attributedInvocation;
}

+ (BOOL)_isDoubleCounting:(FBAEMInvocation *)invocation
                    event:(NSString *)event
{
  // We consider it as double counting if following conditions meet simultaneously
  // 1. The field hasSKAN is true
  // 2. The conversion happens before SKAdNetwork cutoff
  // 3. The event is also being reported by SKAdNetwork
  return invocation.hasSKAN
  && ![self.reporter shouldCutoff]
  && [self.reporter isReportingEvent:event];
}

+ (void)_appendAndSaveInvocation:(FBAEMInvocation *)invocation
{
  [self dispatchOnQueue:g_serialQueue delay:0 block:^() {
    [FBSDKTypeUtility array:g_invocations addObject:invocation];
    [self _saveReportData];
  }];
}

+ (void)_loadConfigurationWithRefreshForced:(BOOL)forced block:(nullable FBAEMReporterBlock)block
{
  [self dispatchOnQueue:g_serialQueue delay:0 block:^() {
    [FBSDKTypeUtility array:g_completionBlocks addObject:block];
    // Executes blocks if there is cache
    if (![self _shouldRefreshWithIsForced:forced]) {
      for (FBAEMReporterBlock executionBlock in g_completionBlocks) {
        executionBlock(nil);
      }
      [g_completionBlocks removeAllObjects];
      return;
    }
    if (g_isLoadingConfiguration) {
      return;
    }
    g_isLoadingConfiguration = YES;

    [self.networker startGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/aem_conversion_configs", self.appID]
                                        parameters:[self _requestParameters]
                                       tokenString:nil
                                        HTTPMethod:FBAEMHTTPMethodGET
                                        completion:^(id _Nullable result, NSError *_Nullable error) {
                                          [self dispatchOnQueue:g_serialQueue delay:0 block:^() {
                                            if (error) {
                                              for (FBAEMReporterBlock executionBlock in g_completionBlocks) {
                                                executionBlock(error);
                                              }
                                              [g_completionBlocks removeAllObjects];
                                              g_isLoadingConfiguration = NO;
                                              return;
                                            }
                                            NSDictionary<NSString *, id> *json = [FBSDKTypeUtility dictionaryValue:result];
                                            if (json) {
                                              g_configRefreshTimestamp = [NSDate date];
                                              [self _addConfigs:[FBSDKTypeUtility dictionary:json objectForKey:@"data" ofType:NSArray.class]];
                                              for (FBAEMReporterBlock executionBlock in g_completionBlocks) {
                                                executionBlock(nil);
                                              }
                                              [g_completionBlocks removeAllObjects];
                                            } else {
                                              NSLog(@"Received invalid AEM config");
                                            }
                                            g_isLoadingConfiguration = NO;
                                          }];
                                        }];
  }];
}

+ (void)_loadCatalogOptimizationWithInvocation:(FBAEMInvocation *)invocation
                                     contentID:(nullable NSString *)contentID
                                         block:(dispatch_block_t)block
{
  [self.networker startGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/aem_conversion_filter", self.appID]
                                      parameters:[self _catalogRequestParameters:invocation.catalogID contentID:contentID]
                                     tokenString:nil
                                      HTTPMethod:FBAEMHTTPMethodGET
                                      completion:^(id _Nullable result, NSError *_Nullable error) {
                                        [self dispatchOnQueue:g_serialQueue delay:0 block:^() {
                                          if (error) {
                                            return;
                                          }
                                          if ([self _isContentOptimized:result]) {
                                            block();
                                          }
                                        }];
                                      }];
}

+ (BOOL)_shouldReportConversionInCatalogLevel:(FBAEMInvocation *)invocation
                                        event:(NSString *)event
{
  return g_isConversionFilteringEnabled
  && g_isCatalogMatchingEnabled
  && invocation.catalogID
  && [invocation isOptimizedEvent:event configs:g_configs];
}

+ (BOOL)_isContentOptimized:(id _Nullable)result
{
  NSDictionary<NSString *, id> *json = [FBSDKTypeUtility dictionaryValue:result];
  NSArray<id> *data = [FBSDKTypeUtility dictionary:json objectForKey:@"data" ofType:NSArray.class];
  NSDictionary<NSString *, id> *catalogData = [FBSDKTypeUtility dictionaryValue:data.firstObject];
  NSNumber *isOptimized = [FBSDKTypeUtility dictionary:catalogData objectForKey:@"content_id_belongs_to_catalog_id" ofType:NSNumber.class] ?: @(NO);
  return isOptimized.boolValue;
}

+ (NSDictionary<NSString *, id> *)_requestParameters
{
  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary new];
  // append business ids to the request params
  NSMutableArray<NSString *> *businessIDs = [NSMutableArray new];
  for (FBAEMInvocation *invocation in g_invocations) {
    [FBSDKTypeUtility array:businessIDs addObject:invocation.businessID];
  }
  NSString *businessIDsString = [FBSDKBasicUtility JSONStringForObject:businessIDs error:nil invalidObjectHandler:nil];
  [FBSDKTypeUtility dictionary:params setObject:businessIDsString forKey:BUSINESS_IDS_KEY];
  [FBSDKTypeUtility dictionary:params setObject:@"" forKey:@"fields"];
  return [params copy];
}

+ (NSDictionary<NSString *, id> *)_catalogRequestParameters:(NSString *)catalogID
                                                  contentID:(NSString *)contentID
{
  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:params setObject:contentID forKey:FB_CONTENT_IDS_KEY];
  [FBSDKTypeUtility dictionary:params setObject:catalogID forKey:CATALOG_ID_KEY];
  return [params copy];
}

+ (BOOL)_isConfigRefreshTimestampValid
{
  return g_configRefreshTimestamp && [[NSDate date] timeIntervalSinceDate:g_configRefreshTimestamp] < FB_AEM_CONFIG_TIME_OUT;
}

+ (BOOL)_shouldRefreshWithIsForced:(BOOL)isForced
{
  if (isForced) {
    return YES;
  }
  // Refresh if there exists invocation which has business ID
  for (FBAEMInvocation *invocation in g_invocations) {
    if (invocation.businessID) {
      return YES;
    }
  }
  // Refresh if timestamp is expired or cached config is empty
  return (![self _isConfigRefreshTimestampValid]) || (0 == g_configs.count);
}

+ (BOOL)_shouldDelayAggregationRequest
{
  return g_minAggregationRequestTimestamp && [[NSDate date] timeIntervalSinceDate:g_minAggregationRequestTimestamp] < 0;
}

#pragma mark - Deeplink debugging methods

+ (void)_sendDebuggingRequest:(FBAEMInvocation *)invocation
{
  NSMutableArray<NSDictionary<NSString *, id> *> *params = [NSMutableArray new];
  [FBSDKTypeUtility array:params addObject:[self _debuggingRequestParameters:invocation]];
  if (0 == params.count) {
    return;
  }
  @try {
    NSData *jsonData = [FBSDKTypeUtility dataWithJSONObject:params options:0 error:nil];
    if (jsonData) {
      NSString *reports = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

      [self.networker startGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/aem_conversions", self.appID]
                                          parameters:@{@"aem_conversions" : reports}
                                         tokenString:nil
                                          HTTPMethod:FBAEMHTTPMethodPOST
                                          completion:^(id _Nullable result, NSError *_Nullable error) {
                                            if (error) {
                                              NSLog(@"Fail to send AEM debugging request with error: %@", error);
                                            }
                                          }];
    }
  } @catch (NSException *exception) {
    NSLog(@"Fail to send AEM debugging request");
  }
}

+ (NSDictionary<NSString *, id> *)_debuggingRequestParameters:(FBAEMInvocation *)invocation
{
  NSMutableDictionary<NSString *, id> *conversionParams = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:conversionParams setObject:invocation.campaignID forKey:CAMPAIGN_ID_KEY];
  [FBSDKTypeUtility dictionary:conversionParams setObject:@(0) forKey:CONVERSION_DATA_KEY];
  [FBSDKTypeUtility dictionary:conversionParams setObject:@(0) forKey:CONSUMPTION_HOUR_KEY];
  [FBSDKTypeUtility dictionary:conversionParams setObject:invocation.ACSToken forKey:TOKEN_KEY];
  [FBSDKTypeUtility dictionary:conversionParams setObject:@"server" forKey:DELAY_FLOW_KEY];

  return [conversionParams copy];
}

#pragma mark - Background methods

+ (nullable NSDate *)_loadMinAggregationRequestTimestamp
{
  NSDate *timestamp = [self.store objectForKey:FBAEMMINAggregationRequestTimestampKey];
  if ([timestamp isKindOfClass:NSDate.class]) {
    return timestamp;
  }
  return nil;
}

+ (void)_updateAggregationRequestTimestamp:(NSTimeInterval)timestamp
{
  g_minAggregationRequestTimestamp = [NSDate dateWithTimeIntervalSince1970:timestamp];
  [self.store setObject:g_minAggregationRequestTimestamp forKey:FBAEMMINAggregationRequestTimestampKey];
}

+ (NSMutableDictionary<NSString *, NSMutableArray<FBAEMConfiguration *> *> *)_loadConfigs
{
  NSData *cachedConfig = [NSData dataWithContentsOfFile:g_configFile options:NSDataReadingMappedIfSafe error:nil];
  if ([cachedConfig isKindOfClass:NSData.class]) {
    NSSet<Class> *classes = [NSSet setWithArray:@[
      NSMutableDictionary.class,
      NSMutableArray.class,
      NSString.class,
      FBAEMConfiguration.class,
      FBAEMRule.class,
      FBAEMEvent.class]];
    NSDictionary<NSString *, NSMutableArray<FBAEMConfiguration *> *> *cache = [FBSDKTypeUtility dictionaryValue:[NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:cachedConfig error:nil]];
    if (cache) {
      return [cache mutableCopy];
    }
  }

  return [NSMutableDictionary new];
}

+ (void)_saveConfigs
{
  if (!g_configs) {
    return;
  }

  NSData *cache = [NSKeyedArchiver archivedDataWithRootObject:g_configs requiringSecureCoding:NO error:nil];
  if (cache && g_configFile) {
    [cache writeToFile:g_configFile atomically:YES];
  }
}

+ (void)_addConfigs:(nullable NSArray<NSDictionary<NSString *, id> *> *)configs
{
  if (0 == configs.count) {
    return;
  }
  for (NSDictionary<NSString *, id> *config in configs) {
    [self _addConfig:[[FBAEMConfiguration alloc] initWithJSON:config]];
  }
  [self _saveConfigs];
}

+ (void)_addConfig:(nullable FBAEMConfiguration *)config
{
  if (!config.configMode) {
    return;
  }
  NSMutableArray<FBAEMConfiguration *> *configs = [FBSDKTypeUtility dictionary:g_configs objectForKey:config.configMode ofType:NSMutableArray.class];
  // Remove the config in the array that has the same "validFrom" and "businessID" as the added config
  NSMutableArray<FBAEMConfiguration *> *res = [NSMutableArray new];
  for (FBAEMConfiguration *c in configs) {
    if ([config isSameValidFrom:c.validFrom businessID:c.businessID]) {
      continue;
    }
    [FBSDKTypeUtility array:res addObject:c];
  }
  [FBSDKTypeUtility array:res addObject:config];
  [FBSDKTypeUtility dictionary:g_configs setObject:res forKey:config.configMode];
  // Sort the configs via "validFrom"
  [res sortUsingComparator:^NSComparisonResult (FBAEMConfiguration *obj1, FBAEMConfiguration *obj2) {
    if (obj1.validFrom > obj2.validFrom) {
      return NSOrderedDescending;
    }
    if (obj1.validFrom < obj2.validFrom) {
      return NSOrderedAscending;
    }
    return NSOrderedSame;
  }];
}

+ (NSMutableArray<FBAEMInvocation *> *)_loadReportData
{
  NSData *cachedReportData = [NSData dataWithContentsOfFile:g_reportFile options:NSDataReadingMappedIfSafe error:nil];
  if ([cachedReportData isKindOfClass:NSData.class]) {
    NSArray<FBAEMInvocation *> *cache = [FBSDKTypeUtility arrayValue:[NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[NSArray.class, FBAEMInvocation.class]] fromData:cachedReportData error:nil]];
    if (cache) {
      return [cache mutableCopy];
    }
  }
  return [NSMutableArray new];
}

+ (void)_saveReportData
{
  NSData *cache = [NSKeyedArchiver archivedDataWithRootObject:g_invocations requiringSecureCoding:NO error:nil];
  if (cache && g_reportFile) {
    [cache writeToFile:g_reportFile atomically:YES];
  }
}

+ (void)_sendAggregationRequest
{
  NSMutableArray<NSDictionary<NSString *, id> *> *params = [NSMutableArray new];
  NSMutableArray<FBAEMInvocation *> *aggregatedInvocations = [NSMutableArray new];
  for (FBAEMInvocation *invocation in g_invocations) {
    if (!invocation.isAggregated) {
      [FBSDKTypeUtility array:params addObject:[self _aggregationRequestParameters:invocation]];
      [FBSDKTypeUtility array:aggregatedInvocations addObject:invocation];
    }
  }
  if (0 == params.count) {
    return;
  }

  dispatch_block_t block = ^{
    @try {
      NSData *jsonData = [FBSDKTypeUtility dataWithJSONObject:params options:0 error:nil];
      if (jsonData) {
        NSString *reports = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        [self.networker startGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/aem_conversions", self.appID]
                                            parameters:@{@"aem_conversions" : reports}
                                           tokenString:nil
                                            HTTPMethod:FBAEMHTTPMethodPOST
                                            completion:^(id _Nullable result, NSError *_Nullable error) {
                                              if (error) {
                                                return;
                                              }

                                              [self dispatchOnQueue:g_serialQueue delay:0 block:^() {
                                                for (FBAEMInvocation *invocation in aggregatedInvocations) {
                                                  invocation.isAggregated = YES;
                                                }
                                                [self _saveReportData];
                                              }];
                                            }];
      }
    } @catch (NSException *exception) {
      NSLog(@"Fail to send AEM reports");
    }
  };

  if ([self _shouldDelayAggregationRequest]) {
    [self dispatchOnQueue:g_serialQueue
                    delay:MAX(FB_AEM_DELAY, (int64_t)(g_minAggregationRequestTimestamp.timeIntervalSince1970 - [[NSDate date] timeIntervalSince1970]))
                    block:block];
  } else {
    block();
  }
  [self _updateAggregationRequestTimestamp:
   MAX(
     [[NSDate date] timeIntervalSince1970] + FB_AEM_DELAY,
     g_minAggregationRequestTimestamp.timeIntervalSince1970 + FB_AEM_DELAY
   )
  ];
}

+ (NSDictionary<NSString *, id> *)_aggregationRequestParameters:(FBAEMInvocation *)invocation
{
  NSInteger delay = 24 + arc4random_uniform(24);
  NSMutableDictionary<NSString *, id> *conversionParams = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:conversionParams setObject:invocation.campaignID forKey:CAMPAIGN_ID_KEY];
  [FBSDKTypeUtility dictionary:conversionParams setObject:@(invocation.conversionValue) forKey:CONVERSION_DATA_KEY];
  [FBSDKTypeUtility dictionary:conversionParams setObject:@(delay) forKey:CONSUMPTION_HOUR_KEY];
  [FBSDKTypeUtility dictionary:conversionParams setObject:invocation.ACSToken forKey:TOKEN_KEY];
  [FBSDKTypeUtility dictionary:conversionParams setObject:@"server" forKey:DELAY_FLOW_KEY];
  [FBSDKTypeUtility dictionary:conversionParams setObject:invocation.ACSConfigID forKey:CONFIG_ID_KEY];
  [FBSDKTypeUtility dictionary:conversionParams setObject:[invocation getHMAC:delay] forKey:HMAC_KEY];
  [FBSDKTypeUtility dictionary:conversionParams setObject:invocation.businessID forKey:BUSINESS_ID_KEY];
  [FBSDKTypeUtility dictionary:conversionParams setObject:@(invocation.isConversionFilteringEligible && g_isConversionFilteringEnabled) forKey:IS_CONVERSION_FILTERING_KEY];

  return [conversionParams copy];
}

+ (void)dispatchOnQueue:(dispatch_queue_t)queue
                  delay:(int64_t)delay
                  block:(dispatch_block_t)block
{
  if (block != nil) {
    if (strcmp(dispatch_queue_get_label(queue), dispatchQueueLabel) == 0) {
      if (delay) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), queue, block);
      } else {
        dispatch_async(queue, block);
      }
    } else {
      if (!delay) {
        block();
      }
    }
  }
}

+ (void)_clearCache
{
  // step 1: clear aggregated invocations that are outside attribution window
  [self _clearInvocations];
  // step 2: clear old configs that are not used anymore and keep the most recent config
  [self _clearConfigs];
}

+ (void)_clearConfigs
{
  BOOL shouldSaveCache = NO;
  if (g_configs.count > 0) {
    NSMutableDictionary<NSString *, NSMutableArray<FBAEMConfiguration *> *> *configs = [NSMutableDictionary new];
    for (NSString *key in g_configs) {
      NSMutableArray<FBAEMConfiguration *> *oldConfigurations = [FBSDKTypeUtility dictionary:g_configs objectForKey:key ofType:NSMutableArray.class];
      NSMutableArray<FBAEMConfiguration *> *newConfigurations = [NSMutableArray new];

      // Removes the last of the old default mode configurations and stores it so it can be
      // added to the array-to-save
      FBAEMConfiguration *lastConfiguration = nil;
      if ([key isEqualToString:@"DEFAULT"]) {
        lastConfiguration = oldConfigurations.lastObject;
        [oldConfigurations removeLastObject];
      }

      for (FBAEMConfiguration *oldConfiguration in oldConfigurations) {
        if (![self _isUsingConfig:oldConfiguration forInvocations:g_invocations]) {
          shouldSaveCache = YES;
          continue;
        }
        [FBSDKTypeUtility array:newConfigurations addObject:oldConfiguration];
      }

      [FBSDKTypeUtility array:newConfigurations addObject:lastConfiguration];
      [FBSDKTypeUtility dictionary:configs setObject:newConfigurations forKey:key];
    }
    g_configs = configs;
  }
  if (shouldSaveCache) {
    [self _saveConfigs];
  }
}

+ (void)_clearInvocations
{
  BOOL isInvocationCacheUpdated = NO;
  if (g_invocations.count > 0) {
    NSMutableArray<FBAEMInvocation *> *res = [NSMutableArray new];
    for (FBAEMInvocation *invocation in g_invocations) {
      if ([invocation isOutOfWindowWithConfigs:g_configs] && invocation.isAggregated) {
        isInvocationCacheUpdated = YES;
        continue;
      }
      [FBSDKTypeUtility array:res addObject:invocation];
    }
    g_invocations = res;
  }
  if (isInvocationCacheUpdated) {
    [self _saveReportData];
  }
}

+ (BOOL)_isUsingConfig:(FBAEMConfiguration *)config
        forInvocations:(NSArray<FBAEMInvocation *> *)invocations
{
  for (FBAEMInvocation *invocation in invocations) {
    if ([config isSameValidFrom:invocation.configID businessID:invocation.businessID]) {
      return YES;
    }
  }
  return NO;
}

#pragma mark - Testability

#if DEBUG

+ (NSMutableDictionary<NSString *, NSMutableArray<FBAEMConfiguration *> *> *)configs
{
  return g_configs;
}

+ (void)setConfigs:(NSMutableDictionary<NSString *, NSMutableArray<FBAEMConfiguration *> *> *)configs
{
  g_configs = configs;
}

+ (void)setInvocations:(NSMutableArray<FBAEMInvocation *> *)invocations
{
  g_invocations = invocations;
}

+ (NSMutableArray<FBAEMInvocation *> *)invocations
{
  return g_invocations;
}

+ (void)setIsEnabled:(BOOL)enabled
{
  g_isAEMReportEnabled = enabled;
}

+ (BOOL)isEnabled
{
  return g_isAEMReportEnabled;
}

+ (void)setIsConversionFilteringEnabled:(BOOL)enabled
{
  g_isConversionFilteringEnabled = enabled;
}

+ (BOOL)isConversionFilteringEnabled
{
  return g_isConversionFilteringEnabled;
}

+ (void)setIsCatalogMatchingEnabled:(BOOL)enabled
{
  g_isCatalogMatchingEnabled = enabled;
}

+ (BOOL)isCatalogMatchingEnabled
{
  return g_isCatalogMatchingEnabled;
}

+ (void)setCompletionBlocks:(NSMutableArray<FBAEMReporterBlock> *)completionBlocks
{
  g_completionBlocks = completionBlocks;
}

+ (void)setQueue:(nullable dispatch_queue_t)queue
{
  g_serialQueue = queue;
}

+ (void)setTimestamp:(NSDate *)timestamp
{
  g_configRefreshTimestamp = timestamp;
}

+ (void)setIsLoadingConfiguration:(BOOL)loading
{
  g_isLoadingConfiguration = loading;
}

+ (NSString *)reportFilePath
{
  return g_reportFile;
}

+ (void)setReportFilePath:(NSString *)path
{
  g_reportFile = path;
}

+ (void)setMinAggregationRequestTimestamp:(NSDate *)timestamp
{
  g_minAggregationRequestTimestamp = timestamp;
}

+ (NSDate *)minAggregationRequestTimestamp
{
  return g_minAggregationRequestTimestamp;
}

+ (void)reset
{
  g_isAEMReportEnabled = NO;
  g_isLoadingConfiguration = NO;
  g_isConversionFilteringEnabled = NO;
  g_isCatalogMatchingEnabled = NO;
  g_completionBlocks = [NSMutableArray new];
  g_configs = [NSMutableDictionary new];
  g_minAggregationRequestTimestamp = nil;
  self.networker = nil;
  self.appID = nil;
  self.reporter = nil;
  self.store = nil;
  [self _clearCache];
}

#endif

@end

#endif
