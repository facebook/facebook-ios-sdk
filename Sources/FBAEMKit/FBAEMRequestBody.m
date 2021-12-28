/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBAEMRequestBody.h"

#import "FBCoreKitBasicsImportForAEMKit.h"

#define kNewline @"\r\n"

typedef void (^AEMCodeBlock)(void);

@interface FBAEMRequestBody ()

@property (nonatomic) NSMutableData *data;
@property (nonatomic) NSMutableDictionary *json;

@end

@implementation FBAEMRequestBody

- (instancetype)init
{
  if ((self = [super init])) {
    _data = [NSMutableData new];
    _json = [NSMutableDictionary dictionary];
  }

  return self;
}

- (void)appendUTF8:(NSString *)utf8
{
  if (!_data.length) {
    NSString *headerUTF8 = [NSString stringWithFormat:@"--%@", kNewline];
    NSData *headerData = [headerUTF8 dataUsingEncoding:NSUTF8StringEncoding];
    [_data appendData:headerData];
  }
  NSData *data = [utf8 dataUsingEncoding:NSUTF8StringEncoding];
  [_data appendData:data];
}

- (void)appendWithKey:(NSString *)key
            formValue:(NSString *)value
{
  [self _appendWithKey:key filename:nil contentType:nil contentBlock:^{
    [self appendUTF8:value];
  }];
  if (key && value) {
    [FBSDKTypeUtility dictionary:_json setObject:value forKey:key];
  }
}

- (NSData *)data
{
  NSData *jsonData;
  if (_json.allKeys.count > 0) {
    jsonData = [FBSDKTypeUtility dataWithJSONObject:_json options:0 error:nil];
  } else {
    jsonData = [NSData data];
  }

  return jsonData;
}

- (void)_appendWithKey:(NSString *)key
              filename:(NSString *)filename
           contentType:(NSString *)contentType
          contentBlock:(AEMCodeBlock)contentBlock
{
  NSMutableArray<NSString *> *disposition = [NSMutableArray new];
  [FBSDKTypeUtility array:disposition addObject:@"Content-Disposition: form-data"];
  if (key) {
    [FBSDKTypeUtility array:disposition addObject:[[NSString alloc] initWithFormat:@"name=\"%@\"", key]];
  }
  if (filename) {
    [FBSDKTypeUtility array:disposition addObject:[[NSString alloc] initWithFormat:@"filename=\"%@\"", filename]];
  }
  [self appendUTF8:[[NSString alloc] initWithFormat:@"%@%@", [disposition componentsJoinedByString:@"; "], kNewline]];
  if (contentType) {
    [self appendUTF8:[[NSString alloc] initWithFormat:@"Content-Type: %@%@", contentType, kNewline]];
  }
  [self appendUTF8:kNewline];
  if (contentBlock != NULL) {
    contentBlock();
  }
  [self appendUTF8:[[NSString alloc] initWithFormat:@"%@", kNewline]];
}

- (nullable NSData *)compressedData
{
  if (!self.data.length) {
    return nil;
  }

  return [FBSDKBasicUtility gzip:self.data];
}

@end

#endif
