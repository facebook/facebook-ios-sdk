/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKEventProcessing.h>
#import <FBSDKCoreKit/FBSDKIntegrityParametersProcessorProvider.h>
#import <FBSDKCoreKit/FBSDKIntegrityProcessing.h>
#import <FBSDKCoreKit/FBSDKRulesFromKeyProvider.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <Foundation/Foundation.h>

@protocol FBSDKFeatureChecking;
@protocol FBSDKGraphRequestFactory;
@protocol FBSDKFileManaging;
@protocol FBSDKDataPersisting;
@protocol FBSDKSettings;
@protocol FBSDKFileDataExtracting;
@protocol FBSDKGateKeeperManaging;
@protocol FBSDKSuggestedEventsIndexer;
@protocol FBSDKFeatureExtracting;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_ModelManager)
@interface FBSDKModelManager : NSObject <FBSDKEventProcessing, FBSDKIntegrityParametersProcessorProvider, FBSDKIntegrityProcessing, FBSDKRulesFromKeyProvider>

@property (class, nonnull, readonly) FBSDKModelManager *shared;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)enable;
- (nullable NSData *)getWeightsForKey:(NSString *)useCase;
- (nullable NSArray<NSNumber *> *)getThresholdsForKey:(NSString *)useCase;
- (BOOL)processIntegrity:(nullable NSString *)param;
- (NSString *)processSuggestedEvents:(NSString *)textFeature denseData:(nullable float *)denseData;

- (void)configureWithFeatureChecker:(id<FBSDKFeatureChecking>)featureChecker
                graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                        fileManager:(id<FBSDKFileManaging>)fileManager
                              store:(id<FBSDKDataPersisting>)store
                           getAppID:(NSString * (^)(void))getAppID
                      dataExtractor:(Class<FBSDKFileDataExtracting>)dataExtractor
                  gateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
             suggestedEventsIndexer:(id<FBSDKSuggestedEventsIndexer>)suggestedEventsIndexer
                   featureExtractor:(Class<FBSDKFeatureExtracting>)featureExtractor
NS_SWIFT_NAME(configure(featureChecker:graphRequestFactory:fileManager:store:getAppID:dataExtractor:gateKeeperManager:suggestedEventsIndexer:featureExtractor:));

@end

NS_ASSUME_NONNULL_END

#endif
