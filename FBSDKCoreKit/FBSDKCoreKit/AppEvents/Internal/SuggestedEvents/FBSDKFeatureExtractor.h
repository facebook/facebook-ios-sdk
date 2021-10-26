/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import "FBSDKFeatureExtracting.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(FeatureExtractor)
@interface FBSDKFeatureExtractor : NSObject

+ (void)loadRulesForKey:(NSString *)useCaseKey;
+ (NSString *)getTextFeature:(NSString *)text
              withScreenName:(NSString *)screenName;
+ (nullable float *)getDenseFeatures:(NSDictionary<NSString *, id> *)viewHierarchy;

@end

// Default conformance to the feature extracting protocol
@interface FBSDKFeatureExtractor (FeatureExtracting) <FBSDKFeatureExtracting>
@end

NS_ASSUME_NONNULL_END

#endif
