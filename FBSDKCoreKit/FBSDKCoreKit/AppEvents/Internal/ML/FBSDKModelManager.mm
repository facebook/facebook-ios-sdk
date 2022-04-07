/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKModelManager.h"

#import "FBSDKAppEventName.h"
#import "FBSDKIntegrityManager.h"
#import "FBSDKMLMacros.h"
#import "FBSDKModelParser.h"
#import "FBSDKModelRuntime.hpp"
#import "FBSDKModelUtility.h"

static NSString *const INTEGRITY_NONE = @"none";
static NSString *const INTEGRITY_ADDRESS = @"address";
static NSString *const INTEGRITY_HEALTH = @"health";

static NSString *_directoryPath;
static NSMutableDictionary<NSString *, id> *_modelInfo;
static std::unordered_map<std::string, fbsdk::MTensor> _MTMLWeights;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKModelManager ()

@property (nullable, nonatomic) id<FBSDKFeatureChecking> featureChecker;
@property (nullable, nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nullable, nonatomic) id<FBSDKFileManaging> fileManager;
@property (nullable, nonatomic) id<FBSDKDataPersisting> store;
@property (nullable, nonatomic) id<FBSDKSettings> settings;
@property (nullable, nonatomic) Class<FBSDKFileDataExtracting> dataExtractor;
@property (nullable, nonatomic) Class<FBSDKGateKeeperManaging> gateKeeperManager;
@property (nullable, nonatomic) id<FBSDKSuggestedEventsIndexer> suggestedEventsIndexer;
@property (nullable, nonatomic) Class<FBSDKFeatureExtracting> featureExtractor;

@end

@implementation FBSDKModelManager

@synthesize integrityParametersProcessor = _integrityParametersProcessor;

typedef void (^FBSDKDownloadCompletionBlock)(void);

// Transitional singleton introduced as a way to change the usage semantics
// from a type-based interface to an instance-based interface.
+ (instancetype)shared
{
  static dispatch_once_t nonce;
  static id instance;
  dispatch_once(&nonce, ^{
    instance = [self new];
  });
  return instance;
}

#pragma mark - Dependency Management

- (void)configureWithFeatureChecker:(id<FBSDKFeatureChecking>)featureChecker
                graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                        fileManager:(id<FBSDKFileManaging>)fileManager
                              store:(id<FBSDKDataPersisting>)store
                           settings:(id<FBSDKSettings>)settings
                      dataExtractor:(Class<FBSDKFileDataExtracting>)dataExtractor
                  gateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
             suggestedEventsIndexer:(id<FBSDKSuggestedEventsIndexer>)suggestedEventsIndexer
                   featureExtractor:(Class<FBSDKFeatureExtracting>)featureExtractor
{
  _featureChecker = featureChecker;
  _graphRequestFactory = graphRequestFactory;
  _fileManager = fileManager;
  _store = store;
  _settings = settings;
  _dataExtractor = dataExtractor;
  _gateKeeperManager = gateKeeperManager;
  _suggestedEventsIndexer = suggestedEventsIndexer;
  _featureExtractor = featureExtractor;
}

#pragma mark - Public methods

static dispatch_once_t enableNonce;

- (void)enable
{
  @try {
    dispatch_once(&enableNonce, ^{
      NSString *languageCode = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
      // If the languageCode could not be fetched successfully, it's regarded as "en" by default.
      if (languageCode && ![languageCode isEqualToString:@"en"]) {
        return;
      }

      _directoryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:FBSDK_ML_MODEL_PATH];
      if (![self.fileManager fileExistsAtPath:_directoryPath]) {
        [self.fileManager createDirectoryAtPath:_directoryPath withIntermediateDirectories:YES attributes:NULL error:NULL];
      }
      _modelInfo = [self.store objectForKey:MODEL_INFO_KEY];
      NSDate *timestamp = [self.store objectForKey:MODEL_REQUEST_TIMESTAMP_KEY];
      if ([_modelInfo count] == 0 || ![self.featureChecker isEnabled:FBSDKFeatureModelRequest] || ![self.class isValidTimestamp:timestamp]) {
        // fetch api
        NSString *graphPath = [NSString stringWithFormat:@"%@/model_asset", self.settings.appID];
        id<FBSDKGraphRequest> request = [self.graphRequestFactory createGraphRequestWithGraphPath:graphPath];
        __weak FBSDKModelManager *weakSelf = self;
        [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
          if (!error) {
            NSDictionary<NSString *, id> *resultDictionary = [FBSDKTypeUtility dictionaryValue:result];
            NSArray<NSDictionary<NSString *, id> *> *rawModels = resultDictionary[MODEL_DATA_KEY];
            if ([rawModels isKindOfClass:NSArray.class]) {
              NSDictionary<NSString *, id> *modelInfo = [weakSelf.class convertToDictionary:rawModels];
              if (modelInfo) {
                _modelInfo = [modelInfo mutableCopy];
                [weakSelf.class processMTML];
                // update cache for model info and timestamp
                [weakSelf.store setObject:_modelInfo forKey:MODEL_INFO_KEY];
                [weakSelf.store setObject:[NSDate date] forKey:MODEL_REQUEST_TIMESTAMP_KEY];
              }
            }
          }
          [self checkFeaturesAndExecuteForMTML];
        }];
      } else {
        [self checkFeaturesAndExecuteForMTML];
      }
    });
  } @catch (NSException *exception) {
    NSLog(@"Fail to enable model manager, exception reason: %@", exception.reason);
  }
}

- (nullable NSDictionary<NSString *, id> *)getRulesForKey:(NSString *)useCase
{
  @try {
    NSDictionary<NSString *, id> *model = [FBSDKTypeUtility dictionary:_modelInfo objectForKey:useCase ofType:NSObject.class];
    if (model && model[VERSION_ID_KEY]) {
      NSString *filePath = [_directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.rules", useCase, model[VERSION_ID_KEY]]];
      if (filePath) {
        NSData *rulesData = [self.dataExtractor dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
        NSDictionary<NSString *, id> *rules = [FBSDKTypeUtility JSONObjectWithData:rulesData options:0 error:nil];
        return rules;
      }
    }
  } @catch (NSException *exception) {
    NSLog(@"Fail to get rules for usecase %@ from ml model, exception reason: %@", useCase, exception.reason);
  }
  return nil;
}

- (nullable NSData *)getWeightsForKey:(NSString *)useCase
{
  if (!_modelInfo || !_directoryPath) {
    return nil;
  }
  if ([useCase hasPrefix:MTMLKey]) {
    useCase = MTMLKey;
  }
  NSDictionary<NSString *, id> *model = [FBSDKTypeUtility dictionary:_modelInfo objectForKey:useCase ofType:NSObject.class];
  if (model && model[VERSION_ID_KEY]) {
    NSString *path = [_directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.weights", useCase, model[VERSION_ID_KEY]]];
    if (!path) {
      return nil;
    }
    return [NSData dataWithContentsOfFile:path
                                  options:NSDataReadingMappedIfSafe
                                    error:nil];
  }
  return nil;
}

- (nullable NSArray<NSNumber *> *)getThresholdsForKey:(NSString *)useCase
{
  if (!_modelInfo) {
    return nil;
  }
  NSDictionary<NSString *, NSArray<NSNumber *> *> *modelInfo = _modelInfo[useCase];
  if (!modelInfo) {
    return nil;
  }
  return modelInfo[THRESHOLDS_KEY];
}

#pragma mark - Integrity Inferencer method

// Used by the `integrityParametersProcessor` which holds a weak reference to this instance
- (BOOL)processIntegrity:(nullable NSString *)param
{
  NSString *integrityType = INTEGRITY_NONE;
  @try {
    if (param.length == 0 || _MTMLWeights.size() == 0) {
      return false;
    }
    NSArray<NSString *> *integrityMapping = [self.class getIntegrityMapping];
    NSString *text = [FBSDKModelUtility normalizedText:param];
    const char *bytes = [text UTF8String];
    if ((int)strlen(bytes) == 0) {
      return false;
    }
    NSArray<NSNumber *> *thresholds = [FBSDKModelManager.shared getThresholdsForKey:MTMLTaskIntegrityDetectKey];
    if (thresholds.count != integrityMapping.count) {
      return false;
    }
    const fbsdk::MTensor &res = fbsdk::predictOnMTML("integrity_detect", bytes, _MTMLWeights, nullptr);
    const float *res_data = res.data();
    for (int i = 0; i < thresholds.count; i++) {
      if ((float)res_data[i] >= (float)[[FBSDKTypeUtility array:thresholds objectAtIndex:i] floatValue]) {
        integrityType = [FBSDKTypeUtility array:integrityMapping objectAtIndex:i];
        break;
      }
    }
  } @catch (NSException *exception) {
    NSLog(@"Fail to process parameter for integrity usecase, exception reason: %@", exception.reason);
  }
  return ![integrityType isEqualToString:INTEGRITY_NONE];
}

#pragma mark - SuggestedEvents Inferencer method

- (NSString *)processSuggestedEvents:(NSString *)textFeature denseData:(nullable float *)denseData
{
  @try {
    NSArray<NSString *> *eventMapping = [FBSDKModelManager getSuggestedEventsMapping];
    if (textFeature.length == 0 || _MTMLWeights.size() == 0 || !denseData) {
      return SUGGESTED_EVENT_OTHER;
    }
    const char *bytes = [textFeature UTF8String];
    if ((int)strlen(bytes) == 0) {
      return SUGGESTED_EVENT_OTHER;
    }

    NSArray<NSNumber *> *thresholds = [FBSDKModelManager.shared getThresholdsForKey:MTMLTaskAppEventPredKey];
    if (thresholds.count != eventMapping.count) {
      return SUGGESTED_EVENT_OTHER;
    }

    const fbsdk::MTensor &res = fbsdk::predictOnMTML("app_event_pred", bytes, _MTMLWeights, denseData);
    const float *res_data = res.data();
    for (int i = 0; i < thresholds.count; i++) {
      if ((float)res_data[i] >= (float)[[FBSDKTypeUtility array:thresholds objectAtIndex:i] floatValue]) {
        return [FBSDKTypeUtility array:eventMapping objectAtIndex:i];
      }
    }
  } @catch (NSException *exception) {
    NSLog(@"Fail to process suggested events, exception reason: %@", exception.reason);
  }
  return SUGGESTED_EVENT_OTHER;
}

#pragma mark - Private methods

+ (BOOL)isValidTimestamp:(NSDate *)timestamp
{
  if (!timestamp) {
    return NO;
  }
  return ([[NSDate date] timeIntervalSinceDate:timestamp] < MODEL_REQUEST_INTERVAL);
}

+ (void)processMTML
{
  NSString *mtmlAssetUri = nil;
  long mtmlVersionId = 0;
  for (NSString *useCase in _modelInfo) {
    if (![useCase isKindOfClass:NSString.class]) {
      continue;
    }
    NSDictionary<NSString *, id> *model = _modelInfo[useCase];
    if ([useCase hasPrefix:MTMLKey]) {
      if (![model[ASSET_URI_KEY] isKindOfClass:NSString.class]
          || ![model[VERSION_ID_KEY] isKindOfClass:NSNumber.class]) {
        continue;
      }
      mtmlAssetUri = model[ASSET_URI_KEY];
      long thisVersionId = [model[VERSION_ID_KEY] longValue];
      mtmlVersionId = thisVersionId > mtmlVersionId ? thisVersionId : mtmlVersionId;
    }
  }
  if (mtmlAssetUri && mtmlVersionId > 0) {
    [FBSDKTypeUtility dictionary:_modelInfo setObject:@{
       USE_CASE_KEY : MTMLKey,
       ASSET_URI_KEY : mtmlAssetUri,
       VERSION_ID_KEY : @(mtmlVersionId),
     } forKey:MTMLKey];
  }
}

- (void)checkFeaturesAndExecuteForMTML
{
  [self getModelAndRules:MTMLKey onSuccess:^() {
    NSData *data = [self getWeightsForKey:MTMLKey];
    _MTMLWeights = [FBSDKModelParser parseWeightsData:data];
    if (![FBSDKModelParser validateWeights:_MTMLWeights forKey:MTMLKey]) {
      return;
    }

    if ([self.featureChecker isEnabled:FBSDKFeatureSuggestedEvents]) {
      [self getModelAndRules:MTMLTaskAppEventPredKey onSuccess:^() {
        [self.featureExtractor loadRulesForKey:MTMLTaskAppEventPredKey];
        [self.suggestedEventsIndexer enable];
      }];
    }

    if ([self.featureChecker isEnabled:FBSDKFeatureIntelligentIntegrity] && self.gateKeeperManager) {
      [self getModelAndRules:MTMLTaskIntegrityDetectKey onSuccess:^() {
        [self setIntegrityParametersProcessor:[[FBSDKIntegrityManager alloc] initWithGateKeeperManager:self.gateKeeperManager
                                                                                    integrityProcessor:self]];
        [[self integrityParametersProcessor] enable];
      }];
    }
  }];
}

- (void)getModelAndRules:(NSString *)useCaseKey
               onSuccess:(FBSDKDownloadCompletionBlock)handler
{
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_group_t group = dispatch_group_create();

  NSDictionary<NSString *, id> *model = [FBSDKTypeUtility dictionary:_modelInfo objectForKey:useCaseKey ofType:NSObject.class];
  if (!model || !_directoryPath) {
    return;
  }

  NSFileManager *fileManager = [NSFileManager defaultManager];
  // download model asset only if not exist before
  NSString *assetUrlString = [FBSDKTypeUtility dictionary:model objectForKey:ASSET_URI_KEY ofType:NSObject.class];
  NSString *assetFilePath;
  if (assetUrlString.length > 0) {
    [self clearCacheForModel:model suffix:@".weights"];
    NSString *fileName = useCaseKey;
    if ([useCaseKey hasPrefix:MTMLKey]) {
      // all mtml tasks share the same weights file
      fileName = MTMLKey;
    }
    assetFilePath = [_directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.weights", fileName, model[VERSION_ID_KEY]]];
    [self download:assetUrlString filePath:assetFilePath queue:queue group:group];
  }

  // download rules
  NSString *rulesUrlString = [FBSDKTypeUtility dictionary:model objectForKey:RULES_URI_KEY ofType:NSObject.class];
  NSString *rulesFilePath = nil;
  // rules are optional and rulesUrlString may be empty
  if (rulesUrlString.length > 0) {
    [self clearCacheForModel:model suffix:@".rules"];
    rulesFilePath = [_directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.rules", useCaseKey, model[VERSION_ID_KEY]]];
    [self download:rulesUrlString filePath:rulesFilePath queue:queue group:group];
  }
  dispatch_group_notify(group,
    dispatch_get_main_queue(), ^{
      if (handler) {
        if ([fileManager fileExistsAtPath:assetFilePath] && (!rulesFilePath || [fileManager fileExistsAtPath:rulesFilePath])) {
          handler();
        }
      }
    });
}

- (void)clearCacheForModel:(NSDictionary<NSString *, id> *)model
                    suffix:(NSString *)suffix
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *useCase = model[USE_CASE_KEY];
  NSString *version = model[VERSION_ID_KEY];
  NSArray<NSString *> *files = [fileManager contentsOfDirectoryAtPath:_directoryPath error:nil];
  NSString *prefixWithVersion = [NSString stringWithFormat:@"%@_%@", useCase, version];
  for (NSString *file in files) {
    if ([file hasSuffix:suffix] && [file hasPrefix:useCase] && ![file hasPrefix:prefixWithVersion]) {
      [fileManager removeItemAtPath:[_directoryPath stringByAppendingPathComponent:file] error:nil];
    }
  }
}

- (void)download:(NSString *)urlString
        filePath:(NSString *)filePath
           queue:(dispatch_queue_t)queue
           group:(dispatch_group_t)group
{
  if (!filePath || [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    return;
  }
  dispatch_group_async(group,
    queue, ^{
      NSURL *url = [NSURL URLWithString:urlString];
      NSData *urlData = [NSData dataWithContentsOfURL:url];
      if (urlData) {
        [urlData writeToFile:filePath atomically:YES];
      }
    });
}

+ (nullable NSMutableDictionary<NSString *, id> *)convertToDictionary:(NSArray<NSDictionary<NSString *, id> *> *)models
{
  if ([models count] == 0) {
    return nil;
  }
  NSMutableDictionary<NSString *, id> *modelInfo = [NSMutableDictionary dictionary];
  for (NSDictionary<NSString *, id> *model in models) {
    if ([model isKindOfClass:NSDictionary.class]
        && [model[USE_CASE_KEY] isKindOfClass:NSString.class]
        && [self isPlistFormatDictionary:model]) {
      [modelInfo addEntriesFromDictionary:@{model[USE_CASE_KEY] : model}];
    }
  }

  if (modelInfo.allKeys.count > 0) {
    return modelInfo;
  } else {
    return nil;
  }
}

+ (BOOL)isPlistFormatDictionary:(NSDictionary<NSString *, id> *)dictionary
{
  __block BOOL isPlistFormat = YES;
  [dictionary enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
    if (![key isKindOfClass:NSString.class]) {
      isPlistFormat = NO;
      *stop = YES;
    }
    if (![obj isKindOfClass:NSArray.class]
        && ![obj isKindOfClass:NSDictionary.class]
        && ![obj isKindOfClass:NSData.class]
        && ![obj isKindOfClass:NSDate.class]
        && ![obj isKindOfClass:NSNumber.class]
        && ![obj isKindOfClass:NSString.class]) {
      isPlistFormat = NO;
      *stop = YES;
    }
  }];

  return isPlistFormat;
}

+ (NSArray<NSString *> *)getIntegrityMapping
{
  return @[INTEGRITY_NONE, INTEGRITY_ADDRESS, INTEGRITY_HEALTH];
}

+ (NSArray<NSString *> *)getSuggestedEventsMapping
{
  return
  @[SUGGESTED_EVENT_OTHER,
    FBSDKAppEventNameCompletedRegistration,
    FBSDKAppEventNameAddedToCart,
    FBSDKAppEventNamePurchased,
    FBSDKAppEventNameInitiatedCheckout];
}

#if DEBUG

+ (void)reset
{
  if (enableNonce) {
    enableNonce = 0;
  }
  _directoryPath = nil;
  _modelInfo = nil;

  self.shared.featureChecker = nil;
  self.shared.graphRequestFactory = nil;
  self.shared.fileManager = nil;
  self.shared.store = nil;
  self.shared.settings = nil;
  self.shared.dataExtractor = nil;
  self.shared.gateKeeperManager = nil;
  self.shared.suggestedEventsIndexer = nil;
  self.shared.featureExtractor = nil;
}

+ (void)setModelInfo:(NSDictionary<NSString *, id> *)modelInfo
{
  _modelInfo = [NSMutableDictionary dictionaryWithDictionary:modelInfo];
}

+ (void)setDirectoryPath:(NSString *)directoryPath
{
  _directoryPath = directoryPath;
}

#endif

@end

NS_ASSUME_NONNULL_END

#endif
