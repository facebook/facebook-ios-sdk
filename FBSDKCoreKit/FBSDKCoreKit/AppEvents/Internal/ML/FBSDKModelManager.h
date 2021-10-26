/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import "FBSDKEventProcessing.h"

@protocol FBSDKDataPersisting;
@protocol FBSDKFeatureChecking;
@protocol FBSDKFileManaging;
@protocol FBSDKGraphRequestFactory;
@protocol FBSDKSettings;
@protocol FBSDKFileDataExtracting;
@protocol FBSDKGateKeeperManaging;
@protocol FBSDKSuggestedEventsIndexer;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ModelManager)
@interface FBSDKModelManager : NSObject <FBSDKEventProcessing>

@property (class, nonnull, readonly) FBSDKModelManager *shared;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)enable;
- (nullable NSData *)getWeightsForKey:(NSString *)useCase;
- (nullable NSArray *)getThresholdsForKey:(NSString *)useCase;
- (BOOL)processIntegrity:(nullable NSString *)param;
- (NSString *)processSuggestedEvents:(NSString *)textFeature denseData:(nullable float *)denseData;
- (void)configureWithFeatureChecker:(id<FBSDKFeatureChecking>)featureChecker
                graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                        fileManager:(id<FBSDKFileManaging>)fileManager
                              store:(id<FBSDKDataPersisting>)store
                           settings:(id<FBSDKSettings>)settings
                      dataExtractor:(Class<FBSDKFileDataExtracting>)dataExtractor
                  gateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
             suggestedEventsIndexer:(id<FBSDKSuggestedEventsIndexer>)suggestedEventsIndexer;

@end

NS_ASSUME_NONNULL_END

#endif
