/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBAEMReporter.h"

#include <stdlib.h>

#import "FBAEMAdvertiserRuleFactory.h"
#import "FBAEMConfiguration.h"
#import "FBAEMInvocation.h"
#import "FBAEMNetworker.h"
#import "FBAEMSettings.h"
#import "FBAEMUtility.h"
#import "FBCoreKitBasicsImportForAEMKit.h"

#define FB_AEM_CONFIG_TIME_OUT 86400

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

static NSString *const FB_CONTENT_IDS_KEY = @"fb_content_ids";
static NSString *const CATALOG_ID_KEY = @"catalog_id";

static NSString *const FBAEMConfigurationKey = @"com.facebook.sdk:FBSDKAEMConfiguration";
static NSString *const FBAEMReporterKey = @"com.facebook.sdk:FBSDKAEMReporter";
static NSString *const FBAEMReporterFileName = @"FBSDKAEMReportData.report";
static NSString *const FBAEMConfigFileName = @"FBSDKAEMReportData.config";
static NSString *const FBAEMHTTPMethodGET = @"GET";
static NSString *const FBAEMHTTPMethodPOST = @"POST";

static BOOL g_isAEMReportEnabled = NO;
static BOOL g_isLoadingConfiguration = NO;
static BOOL g_isCatalogReportEnabled = NO;
static dispatch_queue_t g_serialQueue;
static NSString *g_reportFile;
static NSString *g_configFile;
static NSMutableDictionary<NSString *, NSMutableArray<FBAEMConfiguration *> *> *g_configs;
static NSMutableArray<FBAEMInvocation *> *g_invocations;
static NSDate *g_configRefreshTimestamp;
static NSMutableArray<FBAEMReporterBlock> *g_completionBlocks;

@interface FBAEMReporter ()

@property (class, nullable, nonatomic) id<FBAEMNetworking> networker;
@property (class, nullable, nonatomic) NSString *appID;
@property (class, nullable, nonatomic) id<FBSKAdNetworkReporting> reporter;

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
  if (self == FBAEMReporter.class) {
    self.networker = networker;
    self.appID = appID;
    self.reporter = reporter;
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

static id<FBSKAdNetworkReporting> _reporter;

+ (nullable id<FBSKAdNetworkReporting>)reporter
{
  return _reporter;
}

+ (void)setReporter:(nullable id<FBSKAdNetworkReporting>)reporter
{
  _reporter = reporter;
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
      [self dispatchOnQueue:g_serialQueue block:^() {
        g_configs = [self _loadConfigs];
        g_invocations = [self _loadReportData];
      }];
      [self _loadConfigurationWithBlock:^(NSError *error) {
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
        self.networker = [FBAEMNetworker new];
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

+ (void)setCatalogReportEnabled:(BOOL)enabled
{
  g_isCatalogReportEnabled = enabled;
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
    [self _loadConfigurationWithBlock:^(NSError *error) {
      if (0 == g_configs.count || 0 == g_invocations.count) {
        return;
      }

      FBAEMInvocation *attributedInvocation = [self _attributedInvocation:g_invocations Event:event currency:currency value:value parameters:parameters configs:g_configs];
      if (attributedInvocation) {
        // We will report conversion in catalog level if
        // 1. invocation has catalog id
        // 2. event is optimized
        // 3. event's content id belongs to the catalog
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
                        shouldBoostPriority:NO];
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
  [self dispatchOnQueue:g_serialQueue block:^() {
    [FBSDKTypeUtility array:g_invocations addObject:invocation];
    [self _saveReportData];
  }];
}

+ (void)_loadConfigurationWithBlock:(FBAEMReporterBlock)block
{
  [self dispatchOnQueue:g_serialQueue block:^() {
    [FBSDKTypeUtility array:g_completionBlocks addObject:block];
    // Executes blocks if there is cache
    if (![self _shouldRefresh]) {
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
                                          [self dispatchOnQueue:g_serialQueue block:^() {
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
  if (!contentID) {
    NSLog(@"Content ID is not found for the optimized event");
    return;
  }
  [self.networker startGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/aem_conversion_filter", self.appID]
                                      parameters:[self _catalogRequestParameters:invocation.catalogID contentID:contentID]
                                     tokenString:nil
                                      HTTPMethod:FBAEMHTTPMethodGET
                                      completion:^(id _Nullable result, NSError *_Nullable error) {
                                        [self dispatchOnQueue:g_serialQueue block:^() {
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
  return g_isCatalogReportEnabled
  && invocation.catalogID
  && [invocation isOptimizedEvent:event configs:g_configs];
}

+ (BOOL)_isContentOptimized:(id _Nullable)result
{
  NSDictionary<NSString *, id> *json = [FBSDKTypeUtility dictionaryValue:result];
  NSArray<id> *data = [FBSDKTypeUtility dictionary:json objectForKey:@"data" ofType:NSArray.class];
  NSDictionary<NSString *, id> *catalogData = [FBSDKTypeUtility dictionaryValue:[FBSDKTypeUtility array:data objectAtIndex:0]];
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

+ (BOOL)_shouldRefresh
{
  // Refresh if there exists invocation which has business ID
  for (FBAEMInvocation *invocation in g_invocations) {
    if (invocation.businessID) {
      return YES;
    }
  }
  // Refresh if timestamp is expired or cached config is empty
  return (![self _isConfigRefreshTimestampValid]) || (0 == g_configs.count);
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

+ (NSMutableDictionary<NSString *, NSMutableArray<FBAEMConfiguration *> *> *)_loadConfigs
{
  if (@available(iOS 11.0, *)) {
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
  }
  return [NSMutableDictionary new];
}

+ (void)_saveConfigs
{
  if (!g_configs) {
    return;
  }
  if (@available(iOS 11.0, *)) {
    NSData *cache = [NSKeyedArchiver archivedDataWithRootObject:g_configs requiringSecureCoding:NO error:nil];
    if (cache && g_configFile) {
      [cache writeToFile:g_configFile atomically:YES];
    }
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
  if (@available(iOS 11.0, *)) {
    NSData *cachedReportData = [NSData dataWithContentsOfFile:g_reportFile options:NSDataReadingMappedIfSafe error:nil];
    if ([cachedReportData isKindOfClass:NSData.class]) {
      NSArray<FBAEMInvocation *> *cache = [FBSDKTypeUtility arrayValue:[NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[NSArray.class, FBAEMInvocation.class]] fromData:cachedReportData error:nil]];
      if (cache) {
        return [cache mutableCopy];
      }
    }
  }
  return [NSMutableArray new];
}

+ (void)_saveReportData
{
  if (@available(iOS 11.0, *)) {
    NSData *cache = [NSKeyedArchiver archivedDataWithRootObject:g_invocations requiringSecureCoding:NO error:nil];
    if (cache && g_reportFile) {
      [cache writeToFile:g_reportFile atomically:YES];
    }
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

                                            [self dispatchOnQueue:g_serialQueue block:^() {
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

  return [conversionParams copy];
}

+ (void)dispatchOnQueue:(dispatch_queue_t)queue block:(dispatch_block_t)block
{
  if (block != nil) {
    if (strcmp(dispatch_queue_get_label(queue), dispatchQueueLabel) == 0) {
      dispatch_async(queue, block);
    } else {
      block();
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

#if DEBUG && FBTEST

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

+ (void)setIsCatalogReportEnabled:(BOOL)enabled
{
  g_isCatalogReportEnabled = enabled;
}

+ (BOOL)isCatalogReportEnabled
{
  return g_isCatalogReportEnabled;
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

+ (void)reset
{
  g_isAEMReportEnabled = NO;
  g_isLoadingConfiguration = NO;
  g_isCatalogReportEnabled = NO;
  g_completionBlocks = [NSMutableArray new];
  g_configs = [NSMutableDictionary new];
  self.networker = nil;
  self.appID = nil;
  self.reporter = nil;
  [self _clearCache];
}

#endif

@end

#endif
