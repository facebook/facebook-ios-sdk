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

 #import "FBAEMRequestBody.h"

 #import "FBCoreKitBasicsImportForAEMKit.h"

 #define kNewline @"\r\n"

typedef void (^AEMCodeBlock)(void);

@implementation FBAEMRequestBody
{
  NSMutableData *_data;
  NSMutableDictionary *_json;
}

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
  [self appendUTF8:[[NSString alloc] initWithFormat:@"%@", kNewline]];
}

- (NSData *)compressedData
{
  if (!self.data.length) {
    return nil;
  }

  return [FBSDKBasicUtility gzip:self.data];
}

@end

#endif
