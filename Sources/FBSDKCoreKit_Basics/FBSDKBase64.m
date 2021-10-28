/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKBase64.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKBase64

static FBSDKBase64 *_decoder;
static FBSDKBase64 *_encoder;

#pragma mark - Class Methods

+ (void)initialize
{
  if (self == FBSDKBase64.class) {
    _decoder = [FBSDKBase64 new];
    _encoder = [FBSDKBase64 new];
  }
}

+ (nullable NSData *)decodeAsData:(nullable NSString *)string
{
  return [_decoder decodeAsData:string];
}

+ (nullable NSString *)decodeAsString:(nullable NSString *)string
{
  return [_decoder decodeAsString:string];
}

+ (nullable NSString *)encodeData:(nullable NSData *)data
{
  return [_encoder encodeData:data];
}

+ (nullable NSString *)encodeString:(nullable NSString *)string
{
  return [_encoder encodeString:string];
}

+ (NSString *)base64FromBase64Url:(NSString *)base64Url
{
  NSString *base64 = [base64Url stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
  base64 = [base64 stringByReplacingOccurrencesOfString:@"_" withString:@"/"];

  return base64;
}

#pragma mark - Object Lifecycle

#pragma mark - Implementation Methods

- (nullable NSData *)decodeAsData:(nullable NSString *)string
{
  if (!string) {
    return nil;
  }
  // This padding will be appended before stripping unknown characters, so if there are unknown characters of count % 4
  // it will not be able to decode.  Since we assume valid base64 data, we will take this as is.
  int needPadding = string.length % 4;
  if (needPadding > 0) {
    needPadding = 4 - needPadding;
    string = [string stringByPaddingToLength:string.length + needPadding withString:@"=" startingAtIndex:0];
  }

  return [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

- (nullable NSString *)decodeAsString:(nullable NSString *)string
{
  NSData *data = [self decodeAsData:string];
  if (!data) {
    return nil;
  }
  return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (nullable NSString *)encodeData:(nullable NSData *)data
{
  if (!data) {
    return nil;
  }

  return [data base64EncodedStringWithOptions:0];
}

- (nullable NSString *)encodeString:(nullable NSString *)string
{
  return [self encodeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

@end

NS_ASSUME_NONNULL_END
