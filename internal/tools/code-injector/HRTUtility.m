// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "HRTUtility.h"

#import <CommonCrypto/CommonDigest.h>

#import "HRTInternalUtility.h"

@implementation HRTUtility

+ (NSDictionary *)dictionaryWithQueryString:(NSString *)queryString
{
  return [HRTBasicUtility dictionaryWithQueryString:queryString];
}

+ (NSString *)queryStringWithDictionary:(NSDictionary<NSString *, id> *)dictionary error:(NSError **)errorRef
{
  return [HRTBasicUtility queryStringWithDictionary:dictionary error:errorRef invalidObjectHandler:NULL];
}

+ (NSString *)URLDecode:(NSString *)value
{
  return [HRTBasicUtility URLDecode:value];
}

+ (NSString *)URLEncode:(NSString *)value
{
  return [HRTBasicUtility URLEncode:value];
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

+ (nullable NSString *)SHA256Hash:(nullable NSObject *)input
{
  NSData *data = nil;

  if ([input isKindOfClass:[NSData class]]) {
    data = (NSData *)input;
  } else if ([input isKindOfClass:[NSString class]]) {
    data = [(NSString *)input dataUsingEncoding:NSUTF8StringEncoding];
  }

  if (!data) {
    return nil;
  }

  uint8_t digest[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
  NSMutableString *hashed = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
  for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
    [hashed appendFormat:@"%02x", digest[i]];
  }

  return [hashed copy];
}

@end
