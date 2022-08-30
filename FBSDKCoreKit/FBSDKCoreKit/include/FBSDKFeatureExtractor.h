/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKFeatureExtracting.h>
#import <FBSDKCoreKit/FBSDKRulesFromKeyProvider.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_FeatureExtractor)
@interface FBSDKFeatureExtractor : NSObject <FBSDKFeatureExtracting>

@property (class, nullable, nonatomic) id<FBSDKRulesFromKeyProvider> rulesFromKeyProvider;

+ (void)configureWithRulesFromKeyProvider:(id<FBSDKRulesFromKeyProvider>)rulesFromKeyProvider
NS_SWIFT_NAME(configure(rulesFromKeyProvider:));

+ (void)loadRulesForKey:(NSString *)useCaseKey;

+ (NSString *)getTextFeature:(NSString *)text
              withScreenName:(NSString *)screenName;

+ (nullable float *)getDenseFeatures:(NSDictionary<NSString *, id> *)viewHierarchy;

@end

NS_ASSUME_NONNULL_END

#endif
