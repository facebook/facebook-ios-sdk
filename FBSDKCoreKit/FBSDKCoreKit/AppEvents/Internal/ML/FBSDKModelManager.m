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
static NSString *const RULES_URI_KEY = @"rules_uri";
static NSString *const THRESHOLDS_KEY = @"thresholds";
static NSString *const USE_CASE_KEY = @"use_case";
static NSString *const VERSION_ID_KEY = @"version_id";
static NSString *const MODEL_DATA_KEY = @"data";
static NSString *const SUGGEST_EVENT_KEY = @"SUGGEST_EVENT";

static NSString *_directoryPath;
static NSMutableDictionary<NSString *, id> *_modelInfo;

@implementation FBSDKModelManager

+ (void)enable
{
  NSString *dirPath = [NSTemporaryDirectory() stringByAppendingPathComponent:FBSDK_ML_MODEL_PATH];
  if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
    [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:NO attributes:NULL error:NULL];
  }
  _directoryPath = dirPath;
  _modelInfo = [NSMutableDictionary dictionary];

  // fetch api
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                initWithGraphPath:[NSString stringWithFormat:@"%@/model_asset", [FBSDKSettings appID]]];

  [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    if (error) {
      return;
    }
    NSDictionary<NSString *, id> *resultDictionary = [FBSDKTypeUtility dictionaryValue:result];
    _modelInfo = [self convertToDictionary:resultDictionary[MODEL_DATA_KEY]];
    if (!_modelInfo) {
      return;
    }
    // update cache
    [[NSUserDefaults standardUserDefaults] setObject:_modelInfo forKey:MODEL_INFO_KEY];

    [FBSDKFeatureManager checkFeature:FBSDKFeatureSuggestedEvents completionBlock:^(BOOL enabled) {
      if (enabled) {
        [self getModelAndRules:SUGGEST_EVENT_KEY handler:^(BOOL success){
          if (success) {
            [FBSDKSuggestedEventsIndexer enable];
          }
        }];
      }
    }];

  }];
}

+ (void)getModelAndRules:(NSString *)useCaseKey
                 handler:(FBSDKDownloadCompletionBlock)handler
{
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_group_t group = dispatch_group_create();
  NSDictionary<NSString *, id> *useCaseInfo = [_modelInfo objectForKey:useCaseKey];
  if ([_modelInfo.allKeys count] == 0 || !useCaseInfo) {
    if (handler) {
      handler(NO);
      return;
    }
  }
  NSDictionary<NSString *, id> *model = [_modelInfo objectForKey:useCaseKey];

  // download model asset
  NSString *assetUrlString = [model objectForKey:ASSET_URI_KEY];
  NSString *assetFilePath;
  if (assetUrlString.length > 0) {
    assetFilePath = [_directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.weights", useCaseKey, useCaseInfo[VERSION_ID_KEY]]];
    [self download:assetUrlString filePath:assetFilePath queue:queue group:group];
  }

  // download rules
  NSString *rulesUrlString = [model objectForKey:RULES_URI_KEY];
  NSString *rulesFilePath;
  // rules are optional and rulesUrlString may be empty
  if (rulesUrlString.length > 0) {
    rulesFilePath = [_directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.rules", useCaseKey, useCaseInfo[VERSION_ID_KEY]]];
    [self download:rulesUrlString filePath:rulesFilePath queue:queue group:group];
  }
  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    if (handler) {
      if ([[NSFileManager defaultManager] fileExistsAtPath:assetFilePath] && (!rulesUrlString || (rulesUrlString && [[NSFileManager defaultManager] fileExistsAtPath:rulesFilePath]))) {
          handler(YES);
          return;
      }
      handler(NO);
    }
  });
}

+ (void)download:(NSString *)urlString
        filePath:(NSString *)filePath
           queue:(dispatch_queue_t)queue
           group:(dispatch_group_t)group
{
  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    return;
  }
  dispatch_group_async(group, queue, ^{
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *urlData = [NSData dataWithContentsOfURL:url];
    if (urlData) {
      [urlData writeToFile:filePath atomically:YES];
    }
  });
}

+ (nullable NSMutableDictionary<NSString *, id> *)convertToDictionary:(NSArray<NSDictionary<NSString *, id> *> *)models
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
  return modelInfo;
}

@end
