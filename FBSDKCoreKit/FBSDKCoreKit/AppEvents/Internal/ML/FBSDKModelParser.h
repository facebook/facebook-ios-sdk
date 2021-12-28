/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import "FBSDKTensor.hpp"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ModelParser)
@interface FBSDKModelParser : NSObject

+ (std::unordered_map<std::string, fbsdk::MTensor>)parseWeightsData:(NSData *)weightsData;
+ (bool)validateWeights:(std::unordered_map<std::string, fbsdk::MTensor>)weights forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END

#endif
