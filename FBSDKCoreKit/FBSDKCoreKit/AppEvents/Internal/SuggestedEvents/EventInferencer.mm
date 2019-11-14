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

#import "EventInferencer.h"

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import "../ML/FBSDKModelManager.h"

#import "FeatureExtractor.h"
#include "model_runtime.h"

static NSString *const MODEL_INFO_KEY= @"com.facebook.sdk:FBSDKModelInfo";
static NSString *const THRESHOLDS_KEY = @"thresholds";
static NSString *const SUGGEST_EVENT_KEY = @"SUGGEST_EVENT";
static NSString *const OTHER_EVENT = @"other";

static NSString *const SUGGESTED_EVENT[4] = {@"fb_mobile_add_to_cart", @"fb_mobile_complete_registration", @"other", @"fb_mobile_purchase"};

@implementation EventInferencer : NSObject

static std::unordered_map<std::string, mat::MTensor> _weights;

+ (void)loadWeights
{
  NSData *latestData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FBSDKBetaKitResources.bundle/app_event_pred_v0_new.weights" ofType:nil]];
  _weights = [self loadWeights:latestData];
}

+ (std::unordered_map<std::string, mat::MTensor>)loadWeights:(NSData *)weightsData{
  std::unordered_map<std::string,  mat::MTensor> weights;

  const void *data = weightsData.bytes;
  NSUInteger totalLength =  weightsData.length;

  int totalFloats = 0;
  if (weightsData.length < 4) {
    // Make sure data length is valid
    return weights;
  }

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

  float *floats = (float *)(json + length);
  for (NSString *key in keys) {
    std::string s_name([key UTF8String]);

    std::vector<int64_t> v_shape;
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
    mat::MTensor tensor = mat::mempty(v_shape);
    float *tensor_data = tensor.data<float>();
    memcpy(tensor_data, floats, sizeof(float) * count);
    floats += count;

    weights[s_name] = tensor;
  }

  return weights;
}

+ (NSString *)predict:(NSString *)buttonText
             viewTree:(NSMutableDictionary *)viewTree
              withLog:(BOOL)isPrint
{
  if (buttonText.length == 0) {
    return OTHER_EVENT;
  }

  // Get bytes tensor
  NSString *textFeature = [FeatureExtractor getTextFeature:buttonText withScreenName:viewTree[@"screenname"]];
  const char *bytes = [textFeature UTF8String];
  int *bytes_data = (int *)malloc(sizeof(int) * textFeature.length);
  memset(bytes_data, 0, sizeof(int) * textFeature.length);
  for (int i = 0; i < textFeature.length; i++) {
    bytes_data[i] = bytes[i];
  }

  std::vector<int64_t> bytes_tensor_shape;
  bytes_tensor_shape.push_back(1);
  bytes_tensor_shape.push_back((int64_t)textFeature.length);
  mat::MTensor bytes_tensor = mat::mempty(bytes_tensor_shape);
  int *bytes_tensor_data = bytes_tensor.data<int>();
  memcpy(bytes_tensor_data, bytes_data, sizeof(int) * textFeature.length);
  free(bytes_data);

  // Get dense tensor
  std::vector<int64_t> dense_tensor_shape;
  dense_tensor_shape.push_back(1);
  dense_tensor_shape.push_back(30);
  mat::MTensor dense_tensor = mat::mempty(dense_tensor_shape);
  float *dense_tensor_data = dense_tensor.data<float>();
  float *dense_data = [FeatureExtractor getDenseFeatures:viewTree];
  if (!dense_data) {
    return OTHER_EVENT;
  }
  memcpy(dense_tensor_data, dense_data, sizeof(float) * 30);
  free(dense_data);

  float *res = mat1::predictOnText(bytes, _weights, dense_tensor_data);
  NSMutableDictionary<NSString *, id> *modelInfo = [[NSUserDefaults standardUserDefaults] objectForKey:MODEL_INFO_KEY];
  if (!modelInfo) {
    return OTHER_EVENT;
  }
  NSDictionary<NSString *, id> * suggestedEventModelInfo = [modelInfo objectForKey:SUGGEST_EVENT_KEY];
  if (!suggestedEventModelInfo) {
    return OTHER_EVENT;
  }
  NSMutableArray *thresholds = [suggestedEventModelInfo objectForKey:THRESHOLDS_KEY];
  for (int i = 0; i < thresholds.count; i++ ){
    if ((float)res[i] >= (float)[thresholds[i] floatValue]) {
      return SUGGESTED_EVENT[i];
    }
  }
  return OTHER_EVENT;
}

@end
