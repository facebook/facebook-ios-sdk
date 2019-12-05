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

#import "FBSDKAddressFilterManager.h"

#import "FBSDKAddressInferencer.h"
#import "FBSDKBasicUtility.h"
#import "FBSDKTypeUtility.h"

static BOOL isAddressFilterEnabled = NO;

@implementation FBSDKAddressFilterManager

+ (void)enable
{
  isAddressFilterEnabled = YES;
}

+ (nullable NSDictionary<NSString *, id> *)processParameters:(nullable NSDictionary<NSString *, id> *)parameters
{
  if (!isAddressFilterEnabled || parameters.count == 0) {
    return parameters;
  }
  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
  NSMutableArray<NSString *> *addressParams = [NSMutableArray array];

  for (NSString *key in [parameters keyEnumerator]) {
    BOOL shouldFilterKey = [FBSDKAddressInferencer shouldFilterParam:key] || [FBSDKAddressInferencer shouldFilterParam:[FBSDKTypeUtility stringValue:parameters[key]]];
    if (shouldFilterKey) {
      [addressParams addObject:key];
      [params removeObjectForKey:key];
    }
  }
  if ([addressParams count] > 0) {
    NSString *addressParamsJSONString = [FBSDKBasicUtility JSONStringForObject:addressParams
                                                                            error:NULL
                                                             invalidObjectHandler:NULL];
    [FBSDKBasicUtility dictionary:params setObject:addressParamsJSONString forKey:@"_addressParams"];
  }
  return [params copy];
}

@end
