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

#import "FBSDKEventInferencer.h"

#import <Foundation/Foundation.h>

#import "FBSDKAppEvents+Internal.h"
#import "FBSDKFeatureExtractor.h"
#import "FBSDKModelManager.h"
#import "FBSDKModelParser.h"
#import "FBSDKModelRuntime.hpp"
#import "FBSDKModelUtility.h"
#import "FBSDKMLMacros.h"

#include<stdexcept>

extern FBSDKAppEventName FBSDKAppEventNameCompletedRegistration;
extern FBSDKAppEventName FBSDKAppEventNameAddedToCart;
extern FBSDKAppEventName FBSDKAppEventNamePurchased;
extern FBSDKAppEventName FBSDKAppEventNameInitiatedCheckout;

static NSDictionary<NSString *, NSArray<NSString *> *> *const SUGGESTED_EVENT = @{
  SUGGEST_EVENT_KEY: @[FBSDKAppEventNameAddedToCart, FBSDKAppEventNameCompletedRegistration, SUGGESTED_EVENT_OTHER, FBSDKAppEventNamePurchased],
  MTMLKey: @[SUGGESTED_EVENT_OTHER, FBSDKAppEventNameCompletedRegistration, FBSDKAppEventNameAddedToCart, FBSDKAppEventNamePurchased, FBSDKAppEventNameInitiatedCheckout],
};
static NSDictionary<NSString *, NSString *> *const DEFAULT_PREDICTION = @{SUGGEST_EVENT_KEY: SUGGESTED_EVENT_OTHER};

static NSString *_useCase;
static std::unordered_map<std::string, mat::MTensor> _weights;

@implementation FBSDKEventInferencer : NSObject

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

+ (NSDictionary<NSString *, NSString *> *)predict:(NSString *)buttonText
                                         viewTree:(NSMutableDictionary *)viewTree
                                          withLog:(BOOL)isPrint
{
  if (buttonText.length == 0 || _useCase.length == 0 || _weights.size() == 0) {
    return DEFAULT_PREDICTION;
  }
  try {
    // Get bytes tensor
    NSString *textFeature = [FBSDKModelUtility normalizeText:[FBSDKFeatureExtractor getTextFeature:buttonText withScreenName:viewTree[@"screenname"]]];
    if (textFeature.length == 0) {
      return DEFAULT_PREDICTION;
    }
    const char *bytes = [textFeature UTF8String];
    if ((int)strlen(bytes) == 0) {
      return DEFAULT_PREDICTION;
    }

    // Get dense tensor
    std::vector<int64_t> dense_tensor_shape;
    dense_tensor_shape.push_back(1);
    dense_tensor_shape.push_back(30);
    mat::MTensor dense_tensor = mat::mempty(dense_tensor_shape);
    float *dense_tensor_data = dense_tensor.data<float>();
    float *dense_data = [FBSDKFeatureExtractor getDenseFeatures:viewTree];
    if (!dense_data) {
      return DEFAULT_PREDICTION;
    }

    NSMutableDictionary<NSString *, NSString *> *result = [[NSMutableDictionary alloc] init];

    // Get dense feature string
    NSMutableArray *denseDataArray = [NSMutableArray array];
    for (int i=0; i < 30; i++) {
      [denseDataArray addObject:[NSNumber numberWithFloat: dense_data[i]]];
    }
    [result setObject:[denseDataArray componentsJoinedByString:@","] forKey:DENSE_FEATURE_KEY];

    memcpy(dense_tensor_data, dense_data, sizeof(float) * 30);
    free(dense_data);

    NSString *key = _useCase;
    if ([key isEqualToString:@"MTML"]) {
      key = @"MTML_APP_EVENT_PRED";
    }

    NSMutableDictionary<NSString *, id> *modelInfo = [[NSUserDefaults standardUserDefaults] objectForKey:MODEL_INFO_KEY];
    if (!modelInfo) {
      return DEFAULT_PREDICTION;
    }
    NSDictionary<NSString *, id> * suggestedEventModelInfo = [modelInfo objectForKey:key];
    if (!suggestedEventModelInfo) {
      return DEFAULT_PREDICTION;
    }
    NSMutableArray *thresholds = [suggestedEventModelInfo objectForKey:THRESHOLDS_KEY];
    if (thresholds.count < SUGGESTED_EVENT[_useCase].count) {
      return DEFAULT_PREDICTION;
    }

    float *res = mat1::predictOnText(std::string([key UTF8String]), bytes, _weights, dense_tensor_data);
    for (int i = 0; i < thresholds.count; i++){
      if ((float)res[i] >= (float)[thresholds[i] floatValue]) {
        [result setObject:SUGGESTED_EVENT[_useCase][i] forKey:SUGGEST_EVENT_KEY];
        return result;
      }
    }
  } catch (const std::exception &e) {}
  return DEFAULT_PREDICTION;
}

@end

#endif
