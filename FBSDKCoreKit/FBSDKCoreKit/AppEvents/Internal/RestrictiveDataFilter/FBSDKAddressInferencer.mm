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

#import "FBSDKAddressInferencer.h"

#import "FBSDKModelManager.h"
#import "FBSDKModelParser.h"
#import "FBSDKModelRuntime.hpp"
#import "FBSDKModelUtility.h"
#import "FBSDKStandaloneModel.hpp"

#include<stdexcept>

static NSString *const MODEL_INFO_KEY= @"com.facebook.sdk:FBSDKModelInfo";
static NSString *const THRESHOLDS_KEY = @"thresholds";
static NSString *const DATA_DETECTION_ADDRESS_KEY = @"DATA_DETECTION_ADDRESS";
static NSDictionary<NSString *, NSArray *> *const WEIGHTS_INFO = @{@"embed.weight" : @[@(256), @(64)],
                                                                    @"convs.0.weight" : @[@(32), @(64), @(2)],
                                                                    @"convs.0.bias" : @[@(32)],
                                                                    @"convs.1.weight" : @[@(32), @(64), @(3)],
                                                                    @"convs.1.bias" : @[@(32)],
                                                                    @"convs.2.weight" : @[@(32), @(64), @(5)],
                                                                    @"convs.2.bias" : @[@(32)],
                                                                    @"fc1.weight": @[@(128), @(126)],
                                                                    @"fc1.bias": @[@(128)],
                                                                    @"fc2.weight": @[@(64), @(128)],
                                                                    @"fc2.bias": @[@(64)],
                                                                    @"fc3.weight": @[@(2), @(64)],
                                                                    @"fc3.bias": @[@(2)]};

@implementation FBSDKAddressInferencer : NSObject

static std::unordered_map<std::string, mat::MTensor> _weights;
static std::vector<float> _denseFeature;

+ (void)initializeDenseFeature
{
  std::vector<float> dense_feature(30);
  std::fill(dense_feature.begin(), dense_feature.end(), 0);
  _denseFeature = dense_feature;
}

+ (void)loadWeights
{
  NSString *path = [FBSDKModelManager getWeightsPath:DATA_DETECTION_ADDRESS_KEY];
  if (!path) {
    return;
  }
  NSData *latestData = [NSData dataWithContentsOfFile:path
                                              options:NSDataReadingMappedIfSafe
                                                error:nil];
  if (!latestData) {
    return;
  }
  std::unordered_map<std::string, mat::MTensor> weights = [FBSDKModelParser parseWeightsData:latestData];
  if ([self validateWeights:weights]) {
    _weights = weights;
  }
}

+ (bool)validateWeights: (std::unordered_map<std::string, mat::MTensor>) weights
{
  if (WEIGHTS_INFO.count != weights.size()) {
    return false;
  }
  try {
    for (NSString *key in WEIGHTS_INFO) {
      if (weights.count(std::string([key UTF8String])) == 0) {
        return false;
      }
      mat::MTensor tensor = weights[std::string([key UTF8String])];
      const std::vector<int64_t>& actualSize = tensor.sizes();
      NSArray *expectedSize = WEIGHTS_INFO[key];
      if (actualSize.size() != expectedSize.count) {
        return false;
      }
      for (int i = 0; i < expectedSize.count; i++) {
        if((int)actualSize[i] != (int)[expectedSize[i] intValue]) {
          return false;
        }
      }
    }
  } catch (const std::exception &e) {
    return false;
  }
  return true;
}

+ (BOOL)shouldFilterParam:(nullable NSString *)param
{
  if (!param || _weights.size() == 0 || _denseFeature.size() == 0) {
    return false;
  }

  NSString *text = [FBSDKModelUtility normalizeText:param];
  const char *bytes = [text UTF8String];
  if ((int)strlen(bytes) == 0) {
    return false;
  }
  float *predictedRaw;
  NSMutableDictionary<NSString *, id> *modelInfo = [[NSUserDefaults standardUserDefaults] objectForKey:MODEL_INFO_KEY];
  if (!modelInfo) {
    return false;
  }
  NSDictionary<NSString *, id> * addressModelInfo = [modelInfo objectForKey:DATA_DETECTION_ADDRESS_KEY];
  if (!addressModelInfo) {
    return false;
  }
  NSMutableArray *thresholds = [addressModelInfo objectForKey:THRESHOLDS_KEY];
  float threshold = [thresholds[0] floatValue];
  try {
    predictedRaw = mat1::predictOnText(bytes, _weights, &_denseFeature[0]);
    if (!predictedRaw[1]) {
      return false;
    }
    return predictedRaw[1] >= threshold;
  } catch (const std::exception &e) {
    return false;
  }
}

@end

#endif
