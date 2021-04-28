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

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKAEMReporter.h"

 #include <stdlib.h>

 #import "FBSDKAEMConfiguration.h"
 #import "FBSDKAEMInvocation.h"
 #import "FBSDKCoreKit+Internal.h"

 #define FBSDK_AEM_CONFIG_TIME_OUT 86400

typedef void (^FBSDKAEMReporterBlock)(NSError *);

static NSString *const AL_APPLINK_DATA_KEY = @"al_applink_data";
static NSString *const CAMPAIGN_ID_KEY = @"campaign_id";
static NSString *const CONVERSION_DATA_KEY = @"conversion_data";
static NSString *const CONSUMPTION_HOUR_KEY = @"consumption_hour";
static NSString *const TOKEN_KEY = @"token";
static NSString *const HMAC_KEY = @"hmac";
static NSString *const CONFIG_ID_KEY = @"config_id";
static NSString *const DELAY_FLOW_KEY = @"delay_flow";

static NSString *const FBSDKAEMConfigurationKey = @"com.facebook.sdk:FBSDKAEMConfiguration";
static NSString *const FBSDKAEMReporterKey = @"com.facebook.sdk:FBSDKAEMReporter";
static NSString *const FBSDKAEMReporterFileName = @"FBSDKAEMReportData.report";
static NSString *const FBSDKAEMConfigFileName = @"FBSDKAEMReportData.config";

static BOOL g_isAEMReportEnabled = NO;
static BOOL g_isLoadingConfiguration = NO;
static dispatch_queue_t g_serialQueue;
static NSString *g_reportFile;
static NSString *g_configFile;
static NSMutableDictionary<NSString *, NSMutableArray<FBSDKAEMConfiguration *> *> *g_configs;
static NSMutableArray<FBSDKAEMInvocation *> *g_invocations;
static NSDate *g_configRefreshTimestamp;
static NSMutableArray<FBSDKAEMReporterBlock> *g_completionBlocks;
static id<FBSDKGraphRequestProviding> _requestProvider;

@implementation FBSDKAEMReporter

static char *const dispatchQueueLabel = "com.facebook.appevents.AEM.FBSDKAEMReporter";

+ (void)configureWithRequestProvider:(id<FBSDKGraphRequestProviding>)requestProvider
{
  if (self == [FBSDKAEMReporter class]) {
    _requestProvider = requestProvider;
  }
}

+ (id<FBSDKGraphRequestProviding>)requestProvider
{
  return _requestProvider;
}

+ (void)enable
{
  if (@available(iOS 14.0, *)) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      g_reportFile = [FBSDKBasicUtility persistenceFilePath:FBSDKAEMReporterFileName];
      g_configFile = [FBSDKBasicUtility persistenceFilePath:FBSDKAEMConfigFileName];
      g_completionBlocks = [NSMutableArray new];
      g_serialQueue = dispatch_queue_create(dispatchQueueLabel, DISPATCH_QUEUE_SERIAL);
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
      g_isAEMReportEnabled = YES;
    });
  }
}

+ (void)handleURL:(NSURL *)url
{
  if (!g_isAEMReportEnabled) {
    return;
  }

  FBSDKAEMInvocation *invocation = [self parseURL:url];
  if (!invocation) {
    return;
  }

  [self _appendAndSaveInvocation:invocation];
}

+ (nullable FBSDKAEMInvocation *)parseURL:(NSURL *)url
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

  return [FBSDKAEMInvocation invocationWithAppLinkData:applinkData];
}

+ (void)recordAndUpdateEvent:(NSString *)event
                    currency:(nullable NSString *)currency
                       value:(nullable NSNumber *)value
{
  if (@available(iOS 14.0, *)) {
    if (!g_isAEMReportEnabled || 0 == event.length) {
      return;
    }
    [self _loadConfigurationWithBlock:^(NSError *error) {
      if (0 == g_configs.count || 0 == g_invocations.count) {
        return;
      }
      FBSDKAEMInvocation *invocation = g_invocations.lastObject;
      if ([invocation attributeEvent:event currency:currency value:value configs:g_configs]) {
        if ([invocation updateConversionValueWithConfigs:g_configs]) {
          [self _sendAggregationRequest];
        }
        [self _saveReportData];
      }
    }];
  }
}

+ (void)_appendAndSaveInvocation:(FBSDKAEMInvocation *)invocation
{
  [self dispatchOnQueue:g_serialQueue block:^() {
    [FBSDKTypeUtility array:g_invocations addObject:invocation];
    [self _saveReportData];
  }];
}

+ (void)_loadConfigurationWithBlock:(FBSDKAEMReporterBlock)block
{
  [self dispatchOnQueue:g_serialQueue block:^() {
    [FBSDKTypeUtility array:g_completionBlocks addObject:block];
    // Executes blocks if there is cache
    if ([self _isConfigRefreshTimestampValid] && g_configs.count > 0) {
      for (FBSDKAEMReporterBlock executionBlock in g_completionBlocks) {
        executionBlock(nil);
      }
      [g_completionBlocks removeAllObjects];
      return;
    }
    if (g_isLoadingConfiguration) {
      return;
    }
    g_isLoadingConfiguration = YES;
    id<FBSDKGraphRequest> request = [self.requestProvider createGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/aem_conversion_configs", [FBSDKSettings appID]]
                                                                               parameters:@{}
                                                                              tokenString:nil
                                                                               HTTPMethod:FBSDKHTTPMethodGET
                                                                                    flags:FBSDKGraphRequestFlagSkipClientToken | FBSDKGraphRequestFlagDisableErrorRecovery];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
      [self dispatchOnQueue:g_serialQueue block:^() {
        if (error) {
          for (FBSDKAEMReporterBlock executionBlock in g_completionBlocks) {
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
          for (FBSDKAEMReporterBlock executionBlock in g_completionBlocks) {
            executionBlock(nil);
          }
          [g_completionBlocks removeAllObjects];
        } else {
          [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors logEntry:@"Received invalid AEM config"];
        }
        g_isLoadingConfiguration = NO;
      }];
    }];
  }];
}

+ (BOOL)_isConfigRefreshTimestampValid
{
  return g_configRefreshTimestamp && [[NSDate date] timeIntervalSinceDate:g_configRefreshTimestamp] < FBSDK_AEM_CONFIG_TIME_OUT;
}

 #pragma mark - Bacground methods

+ (NSMutableDictionary<NSString *, NSMutableArray<FBSDKAEMConfiguration *> *> *)_loadConfigs
{
  if (@available(iOS 11.0, *)) {
    NSData *cachedConfig = [NSData dataWithContentsOfFile:g_configFile options:NSDataReadingMappedIfSafe error:nil];
    if ([cachedConfig isKindOfClass:NSData.class]) {
      NSSet *classes = [NSSet setWithArray:@[
        NSMutableDictionary.class,
        NSMutableArray.class,
        FBSDKAEMConfiguration.class,
        FBSDKAEMRule.class,
        FBSDKAEMEvent.class]];
      NSDictionary<NSString *, NSMutableArray<FBSDKAEMConfiguration *> *> *cache = [FBSDKTypeUtility dictionaryValue:[NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:cachedConfig error:nil]];
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

+ (void)_addConfigs:(nullable NSArray<NSDictionary *> *)configs
{
  if (0 == configs.count) {
    return;
  }
  for (NSDictionary *config in configs) {
    [self _addConfig:[[FBSDKAEMConfiguration alloc] initWithJSON:config]];
  }
  [self _saveConfigs];
}

+ (void)_addConfig:(nullable FBSDKAEMConfiguration *)config
{
  if (!config.configMode) {
    return;
  }
  NSMutableArray<FBSDKAEMConfiguration *> *configs = [FBSDKTypeUtility dictionary:g_configs objectForKey:config.configMode ofType:NSMutableArray.class];
  // Remove the config in the array that has the same "validFrom" as the added config
  NSMutableArray<FBSDKAEMConfiguration *> *res = [NSMutableArray new];
  for (FBSDKAEMConfiguration *c in configs) {
    if (c.validFrom == config.validFrom) {
      continue;
    }
    [FBSDKTypeUtility array:res addObject:c];
  }
  [FBSDKTypeUtility array:res addObject:config];
  [FBSDKTypeUtility dictionary:g_configs setObject:res forKey:config.configMode];
  // Sort the configs via "validFrom"
  [res sortUsingComparator:^NSComparisonResult (FBSDKAEMConfiguration *obj1, FBSDKAEMConfiguration *obj2) {
    if (obj1.validFrom > obj2.validFrom) {
      return NSOrderedDescending;
    }
    if (obj1.validFrom < obj2.validFrom) {
      return NSOrderedAscending;
    }
    return NSOrderedSame;
  }];
}

+ (NSMutableArray<FBSDKAEMInvocation *> *)_loadReportData
{
  if (@available(iOS 11.0, *)) {
    NSData *cachedReportData = [NSData dataWithContentsOfFile:g_reportFile options:NSDataReadingMappedIfSafe error:nil];
    if ([cachedReportData isKindOfClass:NSData.class]) {
      NSArray<FBSDKAEMInvocation *> *cache = [FBSDKTypeUtility arrayValue:[NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[NSArray.class, FBSDKAEMInvocation.class]] fromData:cachedReportData error:nil]];
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
  NSMutableArray<NSDictionary *> *params = [NSMutableArray new];
  NSMutableArray<FBSDKAEMInvocation *> *aggregatedInvocations = [NSMutableArray new];
  for (FBSDKAEMInvocation *invocation in g_invocations) {
    if (!invocation.isAggregated) {
      NSInteger delay = 24 + arc4random_uniform(24);
      NSMutableDictionary<NSString *, id> *conversionParams = [NSMutableDictionary new];
      [FBSDKTypeUtility dictionary:conversionParams setObject:invocation.campaignID forKey:CAMPAIGN_ID_KEY];
      [FBSDKTypeUtility dictionary:conversionParams setObject:@(invocation.conversionValue) forKey:CONVERSION_DATA_KEY];
      [FBSDKTypeUtility dictionary:conversionParams setObject:@(delay) forKey:CONSUMPTION_HOUR_KEY];
      [FBSDKTypeUtility dictionary:conversionParams setObject:invocation.ACSToken forKey:TOKEN_KEY];
      [FBSDKTypeUtility dictionary:conversionParams setObject:@"server" forKey:DELAY_FLOW_KEY];
      [FBSDKTypeUtility dictionary:conversionParams setObject:invocation.ACSConfigID forKey:CONFIG_ID_KEY];
      [FBSDKTypeUtility dictionary:conversionParams setObject:[invocation getHMAC:delay] forKey:HMAC_KEY];
      [FBSDKTypeUtility array:params addObject:[conversionParams copy]];
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
      id<FBSDKGraphRequest> request = [self.requestProvider createGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/aem_conversions", FBSDKSettings.appID]
                                                                                 parameters:@{@"aem_conversions" : reports}
                                                                                tokenString:nil
                                                                                 HTTPMethod:FBSDKHTTPMethodPOST
                                                                                      flags:FBSDKGraphRequestFlagSkipClientToken | FBSDKGraphRequestFlagDisableErrorRecovery];
      [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (error) {
          return;
        }

        [self dispatchOnQueue:g_serialQueue block:^() {
          for (FBSDKAEMInvocation *invocation in aggregatedInvocations) {
            invocation.isAggregated = YES;
          }
          [self _saveReportData];
        }];
      }];
    }
  } @catch (NSException *exception) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents logEntry:@"Fail to send AEM reports"];
  }
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
  BOOL isConfigCacheUpdated = NO;
  if (g_configs.count > 0) {
    NSMutableDictionary<NSString *, NSMutableArray<FBSDKAEMConfiguration *> *> *configs = [NSMutableDictionary new];
    for (NSString *key in g_configs) {
      NSMutableArray<FBSDKAEMConfiguration *> *configList = [FBSDKTypeUtility dictionary:g_configs objectForKey:key ofType:NSMutableArray.class];
      NSMutableArray<FBSDKAEMConfiguration *> *newConfigs = [NSMutableArray new];
      for (int i = 0; i < configList.count - 1; i++) {
        FBSDKAEMConfiguration *config = [FBSDKTypeUtility array:configList objectAtIndex:i];
        if (![self _isUsingConfig:config forInvocations:g_invocations]) {
          isConfigCacheUpdated = YES;
          continue;
        }
        [FBSDKTypeUtility array:newConfigs addObject:config];
      }
      [FBSDKTypeUtility array:newConfigs addObject:configList.lastObject];
      [FBSDKTypeUtility dictionary:configs setObject:newConfigs forKey:key];
    }
    g_configs = configs;
  }
  if (isConfigCacheUpdated) {
    [self _saveConfigs];
  }
}

+ (void)_clearInvocations
{
  BOOL isInvocationCacheUpdated = NO;
  if (g_invocations.count > 0) {
    NSMutableArray<FBSDKAEMInvocation *> *res = [NSMutableArray new];
    for (FBSDKAEMInvocation *invocation in g_invocations) {
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

+ (BOOL)_isUsingConfig:(FBSDKAEMConfiguration *)config
        forInvocations:(NSArray<FBSDKAEMInvocation *> *)invocations
{
  for (FBSDKAEMInvocation *invocation in invocations) {
    if (invocation.configID == config.validFrom) {
      return YES;
    }
  }
  return NO;
}

 #pragma mark - Testability

 #if DEBUG
  #if FBSDKTEST

+ (NSMutableDictionary<NSString *, NSMutableArray<FBSDKAEMConfiguration *> *> *)configs
{
  return g_configs;
}

+ (void)setConfigs:(NSMutableDictionary<NSString *, NSMutableArray<FBSDKAEMConfiguration *> *> *)configs
{
  g_configs = configs;
}

+ (void)setInvocations:(NSMutableArray<FBSDKAEMInvocation *> *)invocations
{
  g_invocations = invocations;
}

+ (NSMutableArray<FBSDKAEMInvocation *> *)invocations
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

+ (void)setCompletionBlocks:(NSMutableArray<FBSDKAEMReporterBlock> *)completionBlocks
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

  #endif
 #endif

@end

#endif
