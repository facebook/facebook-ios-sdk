/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKUtility.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAccessToken.h"
#import "FBSDKAuthenticationToken.h"
#import "FBSDKInternalUtility+Internal.h"

@implementation FBSDKUtility

+ (NSDictionary<NSString *, id> *)dictionaryWithQueryString:(NSString *)queryString
{
  return [FBSDKBasicUtility dictionaryWithQueryString:queryString];
}

+ (NSString *)queryStringWithDictionary:(NSDictionary<NSString *, id> *)dictionary error:(NSError **)errorRef
{
  return [FBSDKBasicUtility queryStringWithDictionary:dictionary error:errorRef invalidObjectHandler:NULL];
}

+ (NSString *)URLDecode:(NSString *)value
{
  return [FBSDKBasicUtility URLDecode:value];
}

+ (NSString *)URLEncode:(NSString *)value
{
  return [FBSDKBasicUtility URLEncode:value];
}

+ (dispatch_source_t)startGCDTimerWithInterval:(double)interval block:(dispatch_block_t)block
{
  dispatch_source_t timer = dispatch_source_create(
    DISPATCH_SOURCE_TYPE_TIMER, // source type
    0, // handle
    0, // mask
    dispatch_get_main_queue()
  ); // queue

  dispatch_source_set_timer(
    timer, // dispatch source
    dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), // start
    interval * NSEC_PER_SEC, // interval
    0 * NSEC_PER_SEC
  ); // leeway

  dispatch_source_set_event_handler(timer, block);

  dispatch_resume(timer);

  return timer;
}

+ (void)stopGCDTimer:(dispatch_source_t)timer
{
  if (timer) {
    dispatch_source_cancel(timer);
  }
}

+ (nullable NSString *)SHA256Hash:(NSObject *)input
{
  return [FBSDKBasicUtility SHA256Hash:input];
}

+ (NSString *)getGraphDomainFromToken
{
  return FBSDKAuthenticationToken.currentAuthenticationToken.graphDomain;
}

+ (NSURL *)unversionedFacebookURLWithHostPrefix:(NSString *)hostPrefix
                                           path:(NSString *)path
                                queryParameters:(NSDictionary<NSString *, id> *)queryParameters
                                          error:(NSError *__autoreleasing *)errorRef
{
  return [FBSDKInternalUtility.sharedUtility unversionedFacebookURLWithHostPrefix:hostPrefix
                                                                             path:path
                                                                  queryParameters:queryParameters
                                                                            error:errorRef];
}

@end
