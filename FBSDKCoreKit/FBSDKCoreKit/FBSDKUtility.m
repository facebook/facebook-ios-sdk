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

#import "FBSDKUtility.h"

#import "FBSDKInternalUtility.h"
#import "FBSDKMacros.h"

@implementation FBSDKUtility

+ (NSDictionary *)dictionaryWithQueryString:(NSString *)queryString
{
  NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
  NSArray *parts = [queryString componentsSeparatedByString:@"&"];

  for (NSString *part in parts) {
    if ([part length] == 0) {
      continue;
    }

    NSRange index = [part rangeOfString:@"="];
    NSString *key;
    NSString *value;

    if (index.location == NSNotFound) {
      key = part;
      value = @"";
    } else {
      key = [part substringToIndex:index.location];
      value = [part substringFromIndex:index.location + index.length];
    }

    key = [self URLDecode:key];
    value = [self URLDecode:value];
    if (key && value) {
      result[key] = value;
    }
  }
  return result;
}

+ (NSString *)queryStringWithDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing *)errorRef
{
  return [FBSDKInternalUtility queryStringWithDictionary:dictionary error:errorRef invalidObjectHandler:NULL];
}

+ (NSString *)URLDecode:(NSString *)value
{
  value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
  return value;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (NSString *)URLEncode:(NSString *)value
{
  return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                               (CFStringRef)value,
                                                                               NULL, // characters to leave unescaped
                                                                               CFSTR(":!*();@/&?+$,='"),
                                                                               kCFStringEncodingUTF8);
}
#pragma clang diagnostic pop

- (instancetype)init
{
  FBSDK_NO_DESIGNATED_INITIALIZER();
  return nil;
}

@end
