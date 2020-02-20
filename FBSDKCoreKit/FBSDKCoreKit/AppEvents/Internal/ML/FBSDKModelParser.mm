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

#import "FBSDKModelParser.h"
#import "FBSDKModelConstants.h"

using std::exception;
using std::string;
using std::unordered_map;
using std::vector;
using mat::mempty;
using mat::MTensor;

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKModelParser

+ (unordered_map<string, MTensor>)parseWeightsData:(NSData *)weightsData {
  unordered_map<string,  MTensor> weights;

  const void *data = weightsData.bytes;
  NSUInteger totalLength =  weightsData.length;

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
    NSDictionary<NSString *, id> *info = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:json length:length]
                                                                         options:0
                                                                           error:nil];
    NSArray<NSString *> *keys = [[info allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *key1, NSString *key2) {
      return [key1 compare:key2];
    }];

    int totalFloats = 0;
    float *floats = (float *)(json + length);
    for (NSString *key in keys) {
      NSString *finalKey = key;
      NSString *mapping = [KEYS_MAPPING objectForKey:key];
      if (mapping) {
        finalKey = mapping;
      }
      string s_name([finalKey UTF8String]);

      vector<int64_t> v_shape;
      NSArray<NSString *> *shape = [info objectForKey:key];
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
      MTensor tensor = mempty(v_shape);
      float *tensor_data = tensor.data<float>();
      memcpy(tensor_data, floats, sizeof(float) * count);
      floats += count;

      weights[s_name] = tensor;
    }
  } catch (const exception &e) {}

  return weights;
}

+ (bool)validateWeights:(unordered_map<string, MTensor>)weights forTask:(FBSDKMTMLTask)task {
  NSMutableDictionary<NSString *, NSArray *> *weightsInfoDict = [[NSMutableDictionary alloc] init];
  [weightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];
  switch (task) {
    case FBSDKMTMLTaskAddressDetect:
      [weightsInfoDict addEntriesFromDictionary:AddressDetectSpec];
      break;
    case FBSDKMTMLTaskAppEventPred:
      [weightsInfoDict addEntriesFromDictionary:AppEventPredSpec];
      break;
  }

  return [self _checkWeights:weights withExpectedInfo:weightsInfoDict];
}

+ (bool)validateMTMLWeights:(unordered_map<string, MTensor>)weights {
    NSMutableDictionary<NSString *, NSArray *> *weightsInfoDict = [[NSMutableDictionary alloc] init];
  [weightsInfoDict addEntriesFromDictionary:SharedWeightsInfo];
  [weightsInfoDict addEntriesFromDictionary:MTMLSpec];
  return [self _checkWeights:weights withExpectedInfo:weightsInfoDict];
}

+ (bool)_checkWeights:(unordered_map<string, MTensor>)weights
     withExpectedInfo:(NSDictionary<NSString *, NSArray *> *)weightsInfoDict {
  if (weightsInfoDict.count != weights.size()) {
    return false;
  }
  try {
    for (NSString *key in weightsInfoDict) {
      if (weights.count(string([key UTF8String])) == 0) {
        return false;
      }
      MTensor tensor = weights[string([key UTF8String])];
      const vector<int64_t>& actualSize = tensor.sizes();
      NSArray *expectedSize = weightsInfoDict[key];
      if (actualSize.size() != expectedSize.count) {
        return false;
      }
      for (int i = 0; i < expectedSize.count; i++) {
        if((int)actualSize[i] != (int)[expectedSize[i] intValue]) {
          return false;
        }
      }
    }
  } catch (const exception &e) {
    return false;
  }
  return true;
}

@end

NS_ASSUME_NONNULL_END

#endif
