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

#import "FeatureExtractor.h"
#include "model_runtime.h"

@implementation EventInferencer : NSObject

static std::unordered_map<std::string, mat::MTensor> _weights;

+ (void)initialize
{
  _weights = [self loadWeights];
}

+ (std::unordered_map<std::string, mat::MTensor>)loadWeights
{
  NSData *latestData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FBSDKBetaKitResources.bundle/app_event_pred_v0_new.weights" ofType:nil]];
  return [self loadWeights:latestData];;
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
    buttonText = @" ";
  }

  // Get bytes tensor
  NSString *textFeature = [FeatureExtractor getTextFeature:buttonText withScreenName:viewTree[@"screenname"]];
  const char *bytes = [textFeature UTF8String];
  int *bytes_data = (int *)malloc(sizeof(int) * textFeature.length);
  memset(bytes_data, 0, sizeof(int) * textFeature.length);
  for (int i = 0; i < textFeature.length; i++) {
    bytes_data[i] = bytes[i];
  }
  mat::MTensor bytes_tensor = mat::mempty({1, (int64_t)textFeature.length});
  int *bytes_tensor_data = bytes_tensor.data<int>();
  memcpy(bytes_tensor_data, bytes_data, sizeof(int) * textFeature.length);
  free(bytes_data);

  // Get dense tensor
  mat::MTensor dense_tensor = mat::mempty({1, 30});
  float *dense_tensor_data = dense_tensor.data<float>();
  float *dense_data = [FeatureExtractor getDenseFeatures:viewTree];
  if (!dense_data) {
    return nil;
  }
  memcpy(dense_tensor_data, dense_data, sizeof(float) * 30);
  free(dense_data);

  std::unordered_map<std::string, float> p_result;
  float *res = mat1::predictOnText(bytes, _weights, dense_tensor_data);

  p_result["fb_mobile_add_to_cart"] = res[0];
  p_result["fb_mobile_complete_registration"] = res[1];
  p_result["fb_mobile_other"] = res[2];
  p_result["fb_mobile_purchase"] = res[3];

  NSString *message = @"";
  float max_score = 0;
  std::string predicted;
  for (auto x: p_result) {
    auto event = x.first;
    auto score = x.second;
    if (score > max_score) {
      predicted = x.first;
      max_score = score;
    }
    message = [message stringByAppendingString:@"[Suggested Events] "];
    message = [message stringByAppendingString:[NSString stringWithCString:x.first.c_str() encoding:NSUTF8StringEncoding]];
    message = [message stringByAppendingString:@":  "];
    message = [message stringByAppendingString:@(score).stringValue];
    message = [message stringByAppendingString:@"\n"];
  }
  message = [message stringByAppendingString:@"\n[Suggested Events]"];
  message = [message stringByAppendingString:@"\n[Suggested Events] prediction:  "];
  message = [message stringByAppendingString:[NSString stringWithCString:predicted.c_str() encoding:NSUTF8StringEncoding]];
  NSString *title = @"prediction for: ";
  title = [title stringByAppendingString:buttonText];
  if (isPrint) {
    NSLog(@"\n[Suggested Events] ---------------------------------------------");
    NSLog(@"\n[Suggested Events] %@", title);
    NSLog(@"\n[Suggested Events]");
    NSLog(@"\n[Suggested Events] scores:\n%@", message);
    NSLog(@"\n[Suggested Events] ---------------------------------------------");
  }
  return [NSString stringWithCString:predicted.c_str() encoding:NSUTF8StringEncoding];
}

@end
