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

 #import "FBSDKIntegrityManager.h"

 #import "FBSDKCoreKitBasicsImport.h"
 #import "FBSDKGateKeeperManaging.h"
 #import "FBSDKIntegrityProcessing.h"

@interface FBSDKIntegrityManager ()

@property (nonatomic) Class<FBSDKGateKeeperManaging> gateKeeperManager;
@property (nonatomic, weak) id<FBSDKIntegrityProcessing> integrityProcessor;
@property (nonatomic) BOOL isIntegrityEnabled;
@property (nonatomic) BOOL isSampleEnabled;

@end

@implementation FBSDKIntegrityManager

- (instancetype)initWithGateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
                       integrityProcessor:(id<FBSDKIntegrityProcessing>)integrityProcessor
{
  if ((self = [super init])) {
    _gateKeeperManager = gateKeeperManager;
    _integrityProcessor = integrityProcessor;
  }
  return self;
}

- (void)enable
{
  self.isIntegrityEnabled = YES;
  self.isSampleEnabled = [self.gateKeeperManager boolForKey:@"FBSDKFeatureIntegritySample" defaultValue:false];
}

// Unused parameter eventName is required for conformance to shared protocol for processing app events.
- (nullable NSDictionary<NSString *, id> *)processParameters:(nullable NSDictionary<NSString *, id> *)parameters
                                                   eventName:(NSString *)eventName
{
  if (!self.isIntegrityEnabled || parameters.count == 0) {
    return parameters;
  }
  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
  NSMutableDictionary<NSString *, id> *restrictiveParams = [NSMutableDictionary dictionary];

  for (NSString *key in [parameters keyEnumerator]) {
    NSString *valueString = [FBSDKTypeUtility coercedToStringValue:parameters[key]];
    BOOL shouldFilter = [self.integrityProcessor processIntegrity:key] || [self.integrityProcessor processIntegrity:valueString];
    if (shouldFilter) {
      [FBSDKTypeUtility dictionary:restrictiveParams setObject:self.isSampleEnabled ? valueString : @"" forKey:key];
      [params removeObjectForKey:key];
    }
  }
  if ([restrictiveParams count] > 0) {
    NSString *restrictiveParamsJSONString = [FBSDKBasicUtility JSONStringForObject:restrictiveParams
                                                                             error:NULL
                                                              invalidObjectHandler:NULL];
    [FBSDKTypeUtility dictionary:params setObject:restrictiveParamsJSONString forKey:@"_onDeviceParams"];
  }
  return [params copy];
}

@end

#endif
