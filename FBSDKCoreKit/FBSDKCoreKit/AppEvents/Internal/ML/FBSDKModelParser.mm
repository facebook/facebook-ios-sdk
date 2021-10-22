/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKModelParser.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKMLMacros.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKModelParser

+ (std::unordered_map<std::string, fbsdk::MTensor>)parseWeightsData:(NSData *)weightsData
{
  std::unordered_map<std::string, fbsdk::MTensor> weights;
  if (!weightsData) {
    return weights;
  }

  const void *data = weightsData.bytes;
  NSUInteger totalLength = weightsData.length;

  if (totalLength < 4) {
    // Make sure data length is valid
    return weights;
  }
  try {
    int length;
    memcpy(&length, data, 4);
    if (length + 4 > totalLength) {
      // Make sure data length is valid
      return weights;
    }

    char *json = (char *)data + 4;
    NSDictionary<NSString *, id> *info = [FBSDKTypeUtility JSONObjectWithData:[NSData dataWithBytes:json length:length]
                                                                      options:0
                                                                        error:nil];
    NSArray<NSString *> *keys = [[info allKeys] sortedArrayUsingComparator:^NSComparisonResult (NSString *key1, NSString *key2) {
      return [key1 compare:key2];
    }];

    int totalFloats = 0;
    float *floats = (float *)(json + length);
    NSDictionary<NSString *, NSString *> *keysMapping = [self getKeysMapping];
    for (NSString *key in keys) {
      NSString *finalKey = key;
      NSString *mapping = [FBSDKTypeUtility dictionary:keysMapping objectForKey:key ofType:NSObject.class];
      if (mapping) {
        finalKey = mapping;
      }
      std::string s_name([finalKey UTF8String]);

      std::vector<int> v_shape;
      NSArray<NSString *> *shape = [FBSDKTypeUtility dictionary:info objectForKey:key ofType:NSObject.class];
      int count = 1;
      for (NSNumber *_s in shape) {
        int i = [_s intValue];
        v_shape.push_back(i);
        count *= i;
      }

      totalFloats += count;

      if ((4 + length + totalFloats * 4) > totalLength) {
        // Make sure data length is valid
        break;
      }
      fbsdk::MTensor tensor(v_shape);
      memcpy(tensor.mutable_data(), floats, sizeof(float) * count);
      floats += count;

      weights[s_name] = tensor;
    }
  } catch (const std::exception &e) {}

  return weights;
}

+ (bool)validateWeights:(std::unordered_map<std::string, fbsdk::MTensor>)weights forKey:(NSString *)key
{
  NSMutableDictionary<NSString *, NSArray *> *weightsInfoDict = [NSMutableDictionary new];
  if ([key hasPrefix:MTMLKey]) {
    [weightsInfoDict addEntriesFromDictionary:[self getMTMLWeightsInfo]];
  }
  return [self checkWeights:weights withExpectedInfo:weightsInfoDict];
}

#pragma mark - private methods

+ (NSDictionary<NSString *, NSString *> *)getKeysMapping
{
  return @{
    @"embedding.weight" : @"embed.weight",
    @"dense1.weight" : @"fc1.weight",
    @"dense2.weight" : @"fc2.weight",
    @"dense3.weight" : @"fc3.weight",
    @"dense1.bias" : @"fc1.bias",
    @"dense2.bias" : @"fc2.bias",
    @"dense3.bias" : @"fc3.bias"
  };
}

+ (NSDictionary<NSString *, NSArray *> *)getMTMLWeightsInfo
{
  return @{
    @"embed.weight" : @[@256, @32],
    @"convs.0.weight" : @[@32, @32, @3],
    @"convs.0.bias" : @[@32],
    @"convs.1.weight" : @[@64, @32, @3],
    @"convs.1.bias" : @[@64],
    @"convs.2.weight" : @[@64, @64, @3],
    @"convs.2.bias" : @[@64],
    @"fc1.weight" : @[@128, @190],
    @"fc1.bias" : @[@128],
    @"fc2.weight" : @[@64, @128],
    @"fc2.bias" : @[@64],
    @"integrity_detect.weight" : @[@3, @64],
    @"integrity_detect.bias" : @[@3],
    @"app_event_pred.weight" : @[@5, @64],
    @"app_event_pred.bias" : @[@5]
  };
}

+ (bool)checkWeights:(std::unordered_map<std::string, fbsdk::MTensor>)weights
    withExpectedInfo:(NSDictionary<NSString *, NSArray *> *)weightsInfoDict
{
  if (weightsInfoDict.count != weights.size()) {
    return false;
  }
  try {
    for (NSString *key in weightsInfoDict) {
      if (weights.count(std::string([key UTF8String])) == 0) {
        return false;
      }
      fbsdk::MTensor tensor = weights[std::string([key UTF8String])];
      const std::vector<int> &actualSize = tensor.sizes();
      NSArray *expectedSize = weightsInfoDict[key];
      if (actualSize.size() != expectedSize.count) {
        return false;
      }
      for (int i = 0; i < expectedSize.count; i++) {
        if ((int)actualSize[i] != (int)[[FBSDKTypeUtility array:expectedSize objectAtIndex:i] intValue]) {
          return false;
        }
      }
    }
  } catch (const std::exception &e) {
    return false;
  }
  return true;
}

@end

NS_ASSUME_NONNULL_END

#endif
