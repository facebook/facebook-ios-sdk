/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit-Swift.h>
#import "FBSDKDomainConfiguration.h"
#import "FBSDKDomainConfigurationManager.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKDomainConfiguration+Internal.h"

#define DOMAIN_CONFIGURATION_USER_DEFAULTS_KEY @"com.facebook.sdk:domainConfiguration"
#define DOMAIN_CONFIGURATION_DOMAIN_INFO_FIELD @"server_domain_infos"
#define DOMAIN_CONFIGURATION_KEY @"key"
#define DOMAIN_CONFIGURATION_VALUE @"value"

// TODO: timeout TBD
#define DOMAIN_CONFIGURATION_MANAGER_CACHE_TIMEOUT (60 * 60)
#define INVALID_DOMAIN_EXCEPTION_TIMEOUT 5.0

@interface FBSDKDomainConfigurationManager ()

@property (nonatomic) NSMutableArray<FBSDKDomainConfigurationBlock> *completionBlocks;
@property (nullable, nonatomic) FBSDKDomainConfiguration *domainConfiguration;
@property (nonatomic) BOOL loadingDomainConfiguration;
@property (nullable, nonatomic) NSError *domainConfigurationError;
@property (nullable, nonatomic) NSDate *domainConfigurationErrorTimestamp;
@property (nonatomic) BOOL requeryFinishedForAppStart;

@end

// TODO: timeout TBD
static const NSTimeInterval kTimeout = 4.0;

@implementation FBSDKDomainConfigurationManager

- (instancetype)init
{
  return [self initWithDomainConfiguration:nil];
}

- (instancetype)initWithDomainConfiguration:(nullable FBSDKDomainConfiguration *)domainConfiguration
{
  if ((self = [super init])) {
    _completionBlocks = [NSMutableArray new];
    _domainConfiguration = domainConfiguration;
  }
  return self;
}

+ (instancetype)sharedInstance
{
  static FBSDKDomainConfigurationManager *instance = nil;
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
    instance = [FBSDKDomainConfigurationManager new];
  });
  return instance;
}

- (void)configureWithSettings:(id<FBSDKSettings>)settings
                    dataStore:(id<FBSDKDataPersisting>)dataStore
          graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
{
  self.settings = settings;
  self.dataStore = dataStore;
  self.graphRequestFactory = graphRequestFactory;
  self.graphRequestConnectionFactory = graphRequestConnectionFactory;
}

#pragma mark - Public

- (nonnull FBSDKDomainConfiguration *)cachedDomainConfiguration
{
  @synchronized(self) {
    // load the server configuration if we don't have it already
    [self loadDomainConfigurationWithCompletionBlock:nil];

    // use whatever configuration we have or the default
    return self.domainConfiguration ?: [FBSDKDomainConfiguration defaultDomainConfiguration];
  }
}

- (void)loadDomainConfigurationWithCompletionBlock:(nullable FBSDKDomainConfigurationBlock)completionBlock {
  @try {
    @synchronized(self) {
      // load the configuration from NSUserDefaults
      if (!self.domainConfiguration) {
        NSData *data = [self.dataStore fb_objectForKey:DOMAIN_CONFIGURATION_USER_DEFAULTS_KEY];
        if ([data isKindOfClass:NSData.class]) {
          // decode the configuration
          id<FBSDKObjectDecoding> unarchiver = [FBSDKUnarchiverProvider createSecureUnarchiverFor:data];
          FBSDKDomainConfiguration *domainConfiguration = nil;
          @try {
            domainConfiguration = [unarchiver decodeObjectOfClass:FBSDKDomainConfiguration.class forKey:NSKeyedArchiveRootObjectKey];
          } @catch (NSException *ex) {
            // Ignore decoding error
          } @finally {
            self.domainConfiguration = domainConfiguration;
          }
        }
      }

      if (self.requeryFinishedForAppStart &&
          (self.domainConfiguration && [self _domainConfigurationTimestampIsValid:self.domainConfiguration.timestamp]) &&
          self.domainConfiguration.version >= FBSDKDomainConfigurationVersion) {
        // we have a valid domain configuration, use that
        if (completionBlock) {
          completionBlock();
        }
      }else{
        // hold onto the completion block
        if (completionBlock) {
          [FBSDKTypeUtility array:self.completionBlocks addObject:[completionBlock copy]];
        }

        // check if we are already loading
        if (!self.loadingDomainConfiguration) {
          // load the configuration from the network
          self.loadingDomainConfiguration = YES;
          id<FBSDKGraphRequest> request = [self requestToLoadDomainConfiguration:self.settings.appID];

          // start request with specified timeout instead of the default 180s
          id<FBSDKGraphRequestConnecting> requestConnection = [self.graphRequestConnectionFactory createGraphRequestConnection];
          requestConnection.timeout = kTimeout;
          [requestConnection addRequest:request completion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
            self.requeryFinishedForAppStart = YES;
            [self processLoadRequestResponse:result error:error];
          }];
          [requestConnection start];
        }
      }
    }
  } @catch (NSException *exception) {}
}

#pragma mark - Internal

- (void)processLoadRequestResponse:(id)result error:(nullable NSError *)error
{
  @try {
    if (error) {
      [self _didProcessConfigurationFromNetwork:nil error:error];
      return;
    }

    NSDictionary<NSString *, id> *resultDictionary = [FBSDKTypeUtility dictionaryValue:result];
    NSArray<NSDictionary<NSString *, id> *> *domainInfoDataArray = [FBSDKTypeUtility arrayValue:resultDictionary[@"data"]];
    NSDictionary<NSString *, id> *endpoints = [FBSDKTypeUtility array:domainInfoDataArray objectAtIndex:0];
    NSArray<NSDictionary<NSString *, id> *> *domainInfoArray = [FBSDKTypeUtility arrayValue:endpoints[@"endpoints"]];

    NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *domainInfo = [NSMutableDictionary new];
    for (NSDictionary<NSString *, id> *info in domainInfoArray) {
      [domainInfo setValue:info[DOMAIN_CONFIGURATION_VALUE] forKey:info[DOMAIN_CONFIGURATION_KEY]];
    }

    self.domainConfiguration = [[FBSDKDomainConfiguration alloc] initWithTimestamp:[NSDate date]
                                                                    domainInfo:[domainInfo copy]
    ];

    [self _didProcessConfigurationFromNetwork:self.domainConfiguration error:nil];
  } @catch (NSException *exception) {}
}

- (id<FBSDKGraphRequest>)requestToLoadDomainConfiguration:(NSString *)appID
{
  NSDictionary<NSString *, NSString *> *parameters = @{ @"fields" : @"" };
  NSString *graphPath = [NSString stringWithFormat:@"%@/%@", appID, DOMAIN_CONFIGURATION_DOMAIN_INFO_FIELD];
  return [self.graphRequestFactory createGraphRequestWithGraphPath:graphPath
                                                        parameters:parameters
                                                       tokenString:nil
                                                        HTTPMethod:nil
                                                             flags:FBSDKGraphRequestFlagSkipClientToken | FBSDKGraphRequestFlagDisableErrorRecovery
                                 useAlternativeDefaultDomainPrefix:NO];
}

- (void)_didProcessConfigurationFromNetwork:(FBSDKDomainConfiguration *)domainConfiguration
                                      error:(NSError *)error
{
  @synchronized(self) {
    if (error) {
      // Only set the error if we don't have previously fetched app settings.
      // (i.e., if we have app settings and a new call gets an error, we'll
      // ignore the error and surface the last successfully fetched settings).
      if (_domainConfiguration) {
        // We have older app settings but the refresh received an error.
        // Log and ignore the error.
        NSString *msg = [NSString stringWithFormat:@"loadDomainConfigurationWithCompletionBlock failed with %@", error];
        [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorInformational
                               logEntry:msg];
      }
      _domainConfigurationError = error;
      _domainConfigurationErrorTimestamp = [NSDate date];
    } else {
      _domainConfiguration = domainConfiguration;
      _domainConfigurationError = nil;
      _domainConfigurationErrorTimestamp = nil;
    }

    // update the cached copy in NSUserDefaults
    if (domainConfiguration) {
      NSData *data = [NSKeyedArchiver archivedDataWithRootObject:domainConfiguration requiringSecureCoding:NO error:nil];
      [self.dataStore fb_setObject:data forKey:DOMAIN_CONFIGURATION_USER_DEFAULTS_KEY];
    }
    _loadingDomainConfiguration = NO;
  }

  for (FBSDKDomainConfigurationBlock completionBlock in _completionBlocks) {
    completionBlock();
  }
  [_completionBlocks removeAllObjects];
}

- (BOOL)_domainConfigurationTimestampIsValid:(NSDate *)timestamp
{
  return ([[NSDate date] timeIntervalSinceDate:timestamp] < DOMAIN_CONFIGURATION_MANAGER_CACHE_TIMEOUT);
}

- (void)clearCache
{
  self.domainConfiguration = nil;
  self.domainConfigurationError = nil;
  self.domainConfigurationErrorTimestamp = nil;
  
  [self.dataStore fb_removeObjectForKey:DOMAIN_CONFIGURATION_USER_DEFAULTS_KEY];
}

- (void)processInvalidDomainsIfNeeded:(NSSet<NSString *> *)domainSet {
  if ([domainSet count] == 0) {
    return;
  }

  NSString *message = @"We have pre-populated the tracking domain field for the FBSDK in the Privacy Manifest to help ensure that our services continue to function properly. We do not advise manually adding domains. Listing \"www.facebook.com\" or subdomains of \"facebook.com\" in the tracking domain field of a Privacy Manifest may break functionality.";

  if ([domainSet containsObject:@"www.facebook.com"]) {
    NSLog(@"%@%@", @"<Warning>: ", message);
  }

  NSData *jsonData = [FBSDKTypeUtility dataWithJSONObject:[domainSet allObjects] options:0 error:nil];
  if (!jsonData) {
    return;
  }

  NSString *domains = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  id<FBSDKGraphRequest> request = [self.graphRequestFactory createGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/domain_reports", self.settings.appID]
                                                                                 parameters:@{@"tracking_domains" : domains ?: @""}
                                                                                tokenString:nil
                                                                                 HTTPMethod:FBSDKHTTPMethodPOST
                                                                                      flags:FBSDKGraphRequestFlagNone
                                                          useAlternativeDefaultDomainPrefix:NO];

  [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
    if ([domainSet containsObject:@"facebook.com"] || [domainSet containsObject:@"ep2.facebook.com"]) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(INVALID_DOMAIN_EXCEPTION_TIMEOUT * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
          NSString *errorMsg = [NSString stringWithFormat:@"%@%@", message, @" Developers can set \"Settings.shared.isDomainErrorEnabled\" to \"false\" in order to disable FBSDK Privacy Manifest related errors."];
          @throw [NSException exceptionWithName:@"InvalidOperationException" reason:errorMsg userInfo:nil];
        });
    }
  }];
}

#if DEBUG

- (void)reset
{
  [self clearCache];
  self.settings = nil;
  self.dataStore = nil;
  self.graphRequestFactory = nil;
  self.graphRequestConnectionFactory = nil;
}

#endif

@end
