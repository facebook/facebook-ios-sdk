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

#import "FBSDKBasicUtility+Internal.h"

#import "FBSDKTypeUtility.h"

@interface NSError(FBSDKError)

+ (NSError *)fbInvalidArgumentErrorWithName:(NSString *)name value:(id)value message:(NSString *)message;

@end

@implementation FBSDKBasicUtility (Internal)

+ (NSString *)JSONStringForObject:(id)object
                            error:(NSError *__autoreleasing *)errorRef
             invalidObjectHandler:(FBSDKInvalidObjectHandler)invalidObjectHandler
{
  if (invalidObjectHandler || ![NSJSONSerialization isValidJSONObject:object]) {
    object = [self _convertObjectToJSONObject:object invalidObjectHandler:invalidObjectHandler stop:NULL];
    if (![NSJSONSerialization isValidJSONObject:object]) {
      if (errorRef != NULL) {
        if ([NSError respondsToSelector:@selector(fbInvalidArgumentErrorWithName:value:message:)]) {
          *errorRef = [NSError fbInvalidArgumentErrorWithName:@"object"
                                                        value:object
                                                      message:@"Invalid object for JSON serialization."];
        }
      }
      return nil;
    }
  }
  NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:errorRef];
  if (!data) {
    return nil;
  }
  return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (BOOL)dictionary:(NSMutableDictionary<NSString *, id> *)dictionary
setJSONStringForObject:(id)object
            forKey:(id<NSCopying>)key
             error:(NSError *__autoreleasing *)errorRef
{
  if (!object || !key) {
    return YES;
  }
  NSString *JSONString = [self JSONStringForObject:object error:errorRef invalidObjectHandler:NULL];
  if (!JSONString) {
    return NO;
  }
  [self dictionary:dictionary setObject:JSONString forKey:key];
  return YES;
}

+ (id)_convertObjectToJSONObject:(id)object
            invalidObjectHandler:(FBSDKInvalidObjectHandler)invalidObjectHandler
                            stop:(BOOL *)stopRef
{
  __block BOOL stop = NO;
  if ([object isKindOfClass:[NSString class]] || [object isKindOfClass:[NSNumber class]]) {
    // good to go, keep the object
  } else if ([object isKindOfClass:[NSURL class]]) {
    object = ((NSURL *)object).absoluteString;
  } else if ([object isKindOfClass:[NSDictionary class]]) {
    NSMutableDictionary<NSString *, id> *dictionary = [[NSMutableDictionary alloc] init];
    [(NSDictionary<id, id> *)object enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *dictionaryStop) {
      [self dictionary:dictionary
             setObject:[self _convertObjectToJSONObject:obj invalidObjectHandler:invalidObjectHandler stop:&stop]
                forKey:[FBSDKTypeUtility stringValue:key]];
      if (stop) {
        *dictionaryStop = YES;
      }
    }];
    object = dictionary;
  } else if ([object isKindOfClass:[NSArray class]]) {
    NSMutableArray<id> *array = [[NSMutableArray alloc] init];
    for (id obj in (NSArray *)object) {
      id convertedObj = [self _convertObjectToJSONObject:obj invalidObjectHandler:invalidObjectHandler stop:&stop];
      [self array:array addObject:convertedObj];
      if (stop) {
        break;
      }
    }
    object = array;
  } else {
    object = invalidObjectHandler(object, stopRef);
  }
  if (stopRef != NULL) {
    *stopRef = stop;
  }
  return object;
}

+ (void)dictionary:(NSMutableDictionary<NSString *, id> *)dictionary setObject:(id)object forKey:(id<NSCopying>)key
{
  if (object && key) {
    dictionary[key] = object;
  }
}

+ (void)array:(NSMutableArray *)array addObject:(id)object
{
  if (object) {
    [array addObject:object];
  }
}

+ (id)objectForJSONString:(NSString *)string error:(NSError *__autoreleasing *)errorRef
{
  NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
  if (!data) {
    if (errorRef != NULL) {
      *errorRef = nil;
    }
    return nil;
  }
  return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:errorRef];
}

+ (NSString *)queryStringWithDictionary:(NSDictionary<id, id> *)dictionary
                                  error:(NSError *__autoreleasing *)errorRef
                   invalidObjectHandler:(FBSDKInvalidObjectHandler)invalidObjectHandler
{
  NSMutableString *queryString = [[NSMutableString alloc] init];
  __block BOOL hasParameters = NO;
  if (dictionary) {
    NSMutableArray<NSString *> *keys = [dictionary.allKeys mutableCopy];
    // remove non-string keys, as they are not valid
    [keys filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary<id, id> *bindings) {
      return [evaluatedObject isKindOfClass:[NSString class]];
    }]];
    // sort the keys so that the query string order is deterministic
    [keys sortUsingSelector:@selector(compare:)];
    BOOL stop = NO;
    for (NSString *key in keys) {
      id value = [self convertRequestValue:dictionary[key]];
      if ([value isKindOfClass:[NSString class]]) {
        value = [self URLEncode:value];
      }
      if (invalidObjectHandler && ![value isKindOfClass:[NSString class]]) {
        value = invalidObjectHandler(value, &stop);
        if (stop) {
          break;
        }
      }
      if (value) {
        if (hasParameters) {
          [queryString appendString:@"&"];
        }
        [queryString appendFormat:@"%@=%@", key, value];
        hasParameters = YES;
      }
    }
  }
  if (errorRef != NULL) {
    *errorRef = nil;
  }
  return (queryString.length ? [queryString copy] : nil);
}

+ (id)convertRequestValue:(id)value
{
  if ([value isKindOfClass:[NSNumber class]]) {
    value = ((NSNumber *)value).stringValue;
  } else if ([value isKindOfClass:[NSURL class]]) {
    value = ((NSURL *)value).absoluteString;
  }
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

+ (NSDictionary<NSString *, NSString *> *)dictionaryWithQueryString:(NSString *)queryString
{
  NSMutableDictionary<NSString *, NSString *> *result = [[NSMutableDictionary alloc] init];
  NSArray<NSString *> *parts = [queryString componentsSeparatedByString:@"&"];

  for (NSString *part in parts) {
    if (part.length == 0) {
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

+ (NSString *)URLDecode:(NSString *)value
{
  value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
  return value;
}

@end
