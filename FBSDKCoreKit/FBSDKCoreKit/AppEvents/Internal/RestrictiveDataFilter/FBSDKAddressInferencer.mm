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
#import "FBSDKMLMacros.h"

#include<stdexcept>

@implementation FBSDKAddressInferencer : NSObject

static NSString *_useCase;
static std::unordered_map<std::string, mat::MTensor> _weights;
static std::vector<float> _denseFeature;

+ (void)initializeDenseFeature
{
  std::vector<float> dense_feature(30);
  std::fill(dense_feature.begin(), dense_feature.end(), 0);
  _denseFeature = dense_feature;
}

+ (void)loadWeightsForKey:(NSString *)useCase
{
  @synchronized (self) {
    if (_useCase) {
      return;
    }
    NSData *data = [FBSDKModelManager getWeightsForKey:useCase];
    if (!data) {
      return;
    }
    std::unordered_map<std::string, mat::MTensor> weights = [FBSDKModelParser parseWeightsData:data];
    if ([FBSDKModelParser validateWeights:weights forKey:useCase]) {
      _useCase = useCase;
      _weights = weights;
    }
  }
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

  NSString *key = _useCase;
  if ([key isEqualToString:@"MTML"]) {
    key = @"MTML_ADDRESS_DETECT";
  }

  NSDictionary<NSString *, id> * addressModelInfo = [modelInfo objectForKey:key];
  if (!addressModelInfo) {
    return false;
  }
  NSMutableArray *thresholds = [addressModelInfo objectForKey:THRESHOLDS_KEY];
  float threshold = [thresholds[0] floatValue];
  try {
    predictedRaw = mat1::predictOnText(std::string([key UTF8String]), bytes, _weights, &_denseFeature[0]);
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
