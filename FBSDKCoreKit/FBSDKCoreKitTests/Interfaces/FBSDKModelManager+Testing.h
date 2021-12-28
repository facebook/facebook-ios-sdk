/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKModelManager.h"

@protocol FBSDKFeatureChecking;
@protocol FBSDKFileManaging;
@protocol FBSDKGateKeeperManaging;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKModelManager (Testing)

@property (nullable, nonatomic) id<FBSDKFeatureChecking> featureChecker;
@property (nullable, nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nullable, nonatomic) id<FBSDKFileManaging> fileManager;
@property (nullable, nonatomic) id<FBSDKDataPersisting> store;
@property (nullable, nonatomic) id<FBSDKSettings> settings;
@property (nullable, nonatomic) Class<FBSDKFileDataExtracting> dataExtractor;
@property (nullable, nonatomic) Class<FBSDKGateKeeperManaging> gateKeeperManager;
@property (nullable, nonatomic) id<FBSDKSuggestedEventsIndexer> suggestedEventsIndexer;
@property (class, nullable, nonatomic) NSString *directoryPath;
@property (nullable, nonatomic) Class<FBSDKFeatureExtracting> featureExtractor;

+ (void)setModelInfo:(NSDictionary<NSString *, id> *)modelInfo;
+ (NSArray<NSString *> *)getIntegrityMapping;
+ (NSArray<NSString *> *)getSuggestedEventsMapping;
+ (void)reset;

- (void)configureWithFeatureChecker:(id<FBSDKFeatureChecking>)featureChecker
                graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                        fileManager:(id<FBSDKFileManaging>)fileManager
                              store:(id<FBSDKDataPersisting>)store
                           settings:(id<FBSDKSettings>)settings
                      dataExtractor:(Class<FBSDKFileDataExtracting>)dataExtractor
                  gateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
             suggestedEventsIndexer:(id<FBSDKSuggestedEventsIndexer>)suggestedEventsIndexer
                   featureExtractor:(nonnull Class<FBSDKFeatureExtracting>)featureExtractor;

@end

NS_ASSUME_NONNULL_END
