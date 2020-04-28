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

#import "FBSDKModelCacheManager.h"

#import "FBSDKModelUtility.h"

#define CACHE_INPUT_KEY   @"input"
#define CACHE_OUTPUT_KEY  @"output"

NS_SWIFT_NAME(ModelCache)
@interface FBSDKModelCache : NSObject

- (instancetype)initWithUsecase:(NSString *)usecase
                        version:(NSString *)version;
- (void)addPrediction:(NSString *)prediction
                 text:(NSString *)text
                dense:(nullable float *)dense;
- (NSString *)getPredictionWithText:(NSString *)text
                              dense:(nullable float *)dense;

@end

@implementation FBSDKModelCache
{
  NSString *_usecase;
  NSString *_version;
  NSMutableArray<NSDictionary<NSString *, NSString *> *> *_cache;
}

- (instancetype)initWithUsecase:(NSString *)usecase
                        version:(NSString *)version
{
  if (self = [super init]) {
    if (usecase.length == 0 || version.length == 0) {
      return nil;
    }
    _usecase = usecase;
    _version = version;
    _cache = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)addPrediction:(NSString *)prediction
                 text:(NSString *)text
                dense:(nullable float *)dense
{
  if (text.length == 0 || prediction.length == 0) {
    return;
  }
  NSString *key = [text stringByAppendingString:[FBSDKModelUtility getDenseFeatureString:dense]];
  @synchronized (self) {
    for (int i = 0; i < _cache.count; i++) {
      if ([_cache[i][CACHE_INPUT_KEY] isEqual:key]) {
        [_cache removeObjectAtIndex:i];
        break;
      }
    }
    [_cache addObject:@{
      CACHE_INPUT_KEY: key,
      CACHE_OUTPUT_KEY: prediction
    }];
  }
}

- (nullable NSString *)getPredictionWithText:(NSString *)text
                                       dense:(nullable float *)dense
{
  NSString *key = [text stringByAppendingString:[FBSDKModelUtility getDenseFeatureString:dense]];
  @synchronized (self) {
    for (NSDictionary<NSString *, NSString *> *entry in _cache) {
      if ([entry[CACHE_INPUT_KEY] isEqual:key]) {
        return entry[CACHE_OUTPUT_KEY];
      }
    }
  }
  return nil;
}

@end


static NSMutableDictionary<NSString *, FBSDKModelCache *> *_cache;

@implementation FBSDKModelCacheManager

+ (void)initialize
{
  _cache = [[NSMutableDictionary alloc] init];
}

+ (void)loadCacheWithUsecase:(NSString *)usecase
                     version:(NSString *)version
{
  if (usecase.length == 0) {
    return;
  }
  @synchronized (self) {
    _cache[usecase] = [[FBSDKModelCache alloc] initWithUsecase:usecase version:version];
  }
}

+ (void)addPrediction:(NSString *)prediction
              usecase:(NSString *)usecase
                 text:(NSString *)text
                dense:(nullable float *)dense
{
  FBSDKModelCache *cache;
  @synchronized (self) {
    cache = _cache[usecase];
  }
  [cache addPrediction:prediction text:text dense:dense];
}

+ (NSString *)getPredictionWithText:(NSString *)text
                            usecase:(NSString *)usecase
                              dense:(nullable float *)dense
{
  FBSDKModelCache *cache;
  @synchronized (self) {
    cache = _cache[usecase];
  }
  return [cache getPredictionWithText:text dense:dense];
}

@end
