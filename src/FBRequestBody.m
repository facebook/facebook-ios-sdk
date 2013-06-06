/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBRequestBody.h"
#import "FBSettings+Internal.h"

static NSString *kStringBoundary = @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";

@interface FBRequestBody ()
@property (nonatomic, retain, readonly) NSMutableData *mutableData;
- (void)appendUTF8:(NSString *)utf8;
@end

@implementation FBRequestBody

@synthesize mutableData = _mutableData;

- (id)init
{
    if (self = [super init]) {
        _mutableData = [[NSMutableData alloc] init];
    }

    return self;
}

- (void)dealloc
{
    [_mutableData release];
    [super dealloc];
}

+ (NSString *)mimeContentType
{
    return [NSString stringWithFormat:@"multipart/form-data; boundary=%@", kStringBoundary];
}

- (void)appendUTF8:(NSString *)utf8
{
    if (![self.mutableData length]) {
        NSString *headerUTF8 = [NSString stringWithFormat:@"--%@\r\n", kStringBoundary];
        NSData *headerData = [headerUTF8 dataUsingEncoding:NSUTF8StringEncoding];
        [self.mutableData appendData:headerData];
    }
    NSData *data = [utf8 dataUsingEncoding:NSUTF8StringEncoding];
    [self.mutableData appendData:data];
}

- (void)appendRecordBoundary
{
    NSString *boundary = [NSString stringWithFormat:@"\r\n--%@\r\n", kStringBoundary];
    [self appendUTF8:boundary];
}

- (void)appendWithKey:(NSString *)key
            formValue:(NSString *)value
               logger:(FBLogger *)logger
{
    NSString *disposition =
        [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key];
    [self appendUTF8:disposition];
    [self appendUTF8:value];
    [self appendRecordBoundary];
    [logger appendFormat:@"\n    %@:\t%@", key, (NSString *)value];
}

- (void)appendWithKey:(NSString *)key
                 imageValue:(UIImage *)image
               logger:(FBLogger *)logger
{
    NSString *disposition =
        [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, key];
    [self appendUTF8:disposition];
    [self appendUTF8:@"Content-Type: image/jpeg\r\n\r\n"];
    NSData *data = UIImageJPEGRepresentation(image, [FBSettings defaultJPEGCompressionQuality]);
    [self.mutableData appendData:data];
    [self appendRecordBoundary];
    [logger appendFormat:@"\n    %@:\t<Image - %d kB>", key, [data length] / 1024];
}

- (void)appendWithKey:(NSString *)key
            dataValue:(NSData *)data
               logger:(FBLogger *)logger
{
    NSString *disposition =
        [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, key];
    [self appendUTF8:disposition];
    [self appendUTF8:@"Content-Type: content/unknown\r\n\r\n"];
    [self.mutableData appendData:data];
    [self appendRecordBoundary];
    [logger appendFormat:@"\n    %@:\t<Data - %d kB>", key, [data length] / 1024];
}

- (NSData *)data
{
    // No need to enforce immutability since this is internal-only and sdk will
    // never cast/modify.
    return self.mutableData;
}

@end
