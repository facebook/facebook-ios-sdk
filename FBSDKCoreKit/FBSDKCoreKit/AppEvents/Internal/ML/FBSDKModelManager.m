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

#import "FBSDKModelManager.h"

#import "FBSDKFeatureManager.h"
#import "FBSDKGraphRequest.h"
#import "FBSDKGraphRequestConnection.h"
#import "FBSDKSettings.h"
#import "FBSDKSuggestedEventsIndexer.h"
#import "FBSDKTypeUtility.h"

#define FBSDK_ML_MODEL_PATH @"models"

static NSString *const MODEL_INFO_KEY= @"com.facebook.sdk:FBSDKModelInfo";
static NSString *const ASSET_URI_KEY = @"asset_uri";
static NSString *const THRESHOLDS_KEY = @"thresholds";
static NSString *const USE_CASE_KEY = @"use_case";
static NSString *const VERSION_ID_KEY = @"version_id";
static NSString *const MODEL_DATA_KEY = @"data";
static NSString *const SUGGEST_EVENT_KEY = @"SUGGEST_EVENT";

static NSString *_directoryPath;
static NSMutableDictionary<NSString *, NSString *> *_modelUris;

@implementation FBSDKModelManager

+ (void)enable
{
  NSString *dirPath = [NSTemporaryDirectory() stringByAppendingPathComponent:FBSDK_ML_MODEL_PATH];
  if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
    [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:NO attributes:NULL error:NULL];
  }
  _directoryPath = dirPath;

  // fetch api
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                initWithGraphPath:[NSString stringWithFormat:@"%@/model_asset", [FBSDKSettings appID]]];

  [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    if (error) {
      return;
    }
    NSDictionary<NSString *, id> *resultDictionary = [FBSDKTypeUtility dictionaryValue:result];
    NSDictionary<NSString *, id> *modelInfo = [self convertToDictionary:resultDictionary[MODEL_DATA_KEY]];
    if (!modelInfo) {
      return;
    }
    _modelUris = [NSMutableDictionary dictionary];
    for (NSString *useCase in modelInfo.allKeys) {
      if ([modelInfo[useCase] objectForKey:ASSET_URI_KEY]) {
        [_modelUris setValue:modelInfo[useCase][ASSET_URI_KEY] forKey:useCase];
      }
    }
    // update cache
    [[NSUserDefaults standardUserDefaults] setObject:modelInfo forKey:MODEL_INFO_KEY];

    [FBSDKFeatureManager checkFeature:FBSDKFeatureSuggestedEvents completionBlock:^(BOOL enabled) {
      if (enabled) {
        [self getModel:SUGGEST_EVENT_KEY];
      }
    }];

  }];
}

+ (void)getModel:(NSString *)useCaseKey
{
  NSDictionary<NSString *, id> *modelInfo = [[NSUserDefaults standardUserDefaults] objectForKey:MODEL_INFO_KEY];
  NSDictionary<NSString *, id> *useCaseInfo = [modelInfo objectForKey:useCaseKey];
  if ([modelInfo.allKeys count] == 0 || !useCaseInfo) {
    return;
  }
  NSString *urlString = [_modelUris objectForKey:useCaseKey];
  if (urlString) {
    NSString *filePath = [_directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.weights", useCaseKey, useCaseInfo[VERSION_ID_KEY]]];

    // filePath is nil or file already exist
    if (!filePath || [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
      return;
    }

    NSURL *url = [NSURL URLWithString:urlString];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      NSData *urlData = [NSData dataWithContentsOfURL:url];
      if (urlData) {
        [urlData writeToFile:filePath atomically:YES];
      }
    });
  }
}

+ (nullable NSDictionary<NSString *, id> *)convertToDictionary:(NSArray<NSDictionary<NSString *, id> *> *)models
{
  if ([models count] == 0) {
    return nil;
  }
  NSMutableDictionary<NSString *, id> *modelInfo = [NSMutableDictionary dictionary];
  for (NSDictionary<NSString *, id> *model in models) {
    if (model[USE_CASE_KEY]) {
      [modelInfo addEntriesFromDictionary:@{model[USE_CASE_KEY]:model}];
    }
  }
  return [modelInfo copy];
}

@end
