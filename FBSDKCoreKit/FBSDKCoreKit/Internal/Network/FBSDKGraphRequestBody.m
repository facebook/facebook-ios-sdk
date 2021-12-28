/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGraphRequestBody.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKConstants.h"
#import "FBSDKGraphRequestDataAttachment.h"
#import "FBSDKLogger.h"
#import "FBSDKLogger+Internal.h"
#import "FBSDKRandom.h"
#import "FBSDKSettings.h"

#define kNewline @"\r\n"

@interface FBSDKGraphRequestBody ()

@property (nonatomic) NSMutableData *data;
@property (nonatomic) NSMutableDictionary<NSString *, id> *json;
@property (nonatomic) NSString *stringBoundary;

@end

@implementation FBSDKGraphRequestBody

- (instancetype)init
{
  if ((self = [super init])) {
    _stringBoundary = fb_randomString(32);
    _data = [NSMutableData new];
    _json = [NSMutableDictionary dictionary];
    _requiresMultipartDataFormat = NO;
  }

  return self;
}

- (NSString *)mimeContentType
{
  if (self.requiresMultipartDataFormat) {
    return [NSString stringWithFormat:@"multipart/form-data; boundary=%@", _stringBoundary];
  } else {
    return @"application/json";
  }
}

- (void)appendUTF8:(NSString *)utf8
{
  if (!_data.length) {
    NSString *headerUTF8 = [NSString stringWithFormat:@"--%@%@", _stringBoundary, kNewline];
    NSData *headerData = [headerUTF8 dataUsingEncoding:NSUTF8StringEncoding];
    [_data appendData:headerData];
  }
  NSData *data = [utf8 dataUsingEncoding:NSUTF8StringEncoding];
  [_data appendData:data];
}

- (void)appendWithKey:(NSString *)key
            formValue:(NSString *)value
               logger:(nullable FBSDKLogger *)logger
{
  [self _appendWithKey:key filename:nil contentType:nil contentBlock:^{
    [self appendUTF8:value];
  }];
  if (key && value) {
    [FBSDKTypeUtility dictionary:_json setObject:value forKey:key];
  }
  [logger appendFormat:@"\n    %@:\t%@", key, (NSString *)value];
}

- (void)appendWithKey:(NSString *)key
           imageValue:(UIImage *)image
               logger:(nullable FBSDKLogger *)logger
{
  NSData *data = UIImageJPEGRepresentation(image, FBSDKSettings.sharedSettings.JPEGCompressionQuality);
  [self _appendWithKey:key filename:key contentType:@"image/jpeg" contentBlock:^{
    [self->_data appendData:data];
  }];
  self.requiresMultipartDataFormat = YES;
  [logger appendFormat:@"\n    %@:\t<Image - %lu kB>", key, (unsigned long)(data.length / 1024)];
}

- (void)appendWithKey:(NSString *)key
            dataValue:(NSData *)data
               logger:(nullable FBSDKLogger *)logger
{
  [self _appendWithKey:key filename:key contentType:@"content/unknown" contentBlock:^{
    [self->_data appendData:data];
  }];
  self.requiresMultipartDataFormat = YES;
  [logger appendFormat:@"\n    %@:\t<Data - %lu kB>", key, (unsigned long)(data.length / 1024)];
}

- (void)appendWithKey:(NSString *)key
  dataAttachmentValue:(FBSDKGraphRequestDataAttachment *)dataAttachment
               logger:(nullable FBSDKLogger *)logger
{
  NSString *filename = dataAttachment.filename ?: key;
  NSString *contentType = dataAttachment.contentType ?: @"content/unknown";
  NSData *data = dataAttachment.data;
  [self _appendWithKey:key filename:filename contentType:contentType contentBlock:^{
    [self->_data appendData:data];
  }];
  self.requiresMultipartDataFormat = YES;
  [logger appendFormat:@"\n    %@:\t<Data - %lu kB>", key, (unsigned long)(data.length / 1024)];
}

- (NSData *)data
{
  if (self.requiresMultipartDataFormat) {
    return [_data copy];
  } else {
    NSData *jsonData;
    if (_json.allKeys.count > 0) {
      jsonData = [FBSDKTypeUtility dataWithJSONObject:_json options:0 error:nil];
    } else {
      jsonData = [NSData data];
    }

    return jsonData;
  }
}

- (void)_appendWithKey:(NSString *)key
              filename:(NSString *)filename
           contentType:(NSString *)contentType
          contentBlock:(FBSDKCodeBlock)contentBlock
{
  NSMutableArray *disposition = [NSMutableArray new];
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
  [self appendUTF8:[[NSString alloc] initWithFormat:@"%@--%@%@", kNewline, _stringBoundary, kNewline]];
}

- (nullable NSData *)compressedData
{
  if (!self.data.length || ![[self mimeContentType] isEqualToString:@"application/json"]) {
    return nil;
  }

  return [FBSDKBasicUtility gzip:self.data];
}

@end
