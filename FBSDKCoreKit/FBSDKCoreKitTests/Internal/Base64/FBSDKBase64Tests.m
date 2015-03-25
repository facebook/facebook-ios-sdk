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

#import <Foundation/Foundation.h>

#import <XCTest/XCTest.h>

#import "FBSDKBase64.h"

@interface FBSDKBase64 (FBSDKBase64Tests)

- (instancetype)initWithOptionsEnabled:(BOOL)optionsEnabled;
- (NSData *)decodeAsData:(NSString *)string;
- (NSString *)decodeAsString:(NSString *)string;
- (NSString *)encodeData:(NSData *)data;
- (NSString *)encodeString:(NSString *)string;

@end

@interface FBSDKBase64Tests : XCTestCase

@end

@implementation FBSDKBase64Tests

- (void)runBackwardCompatibilityWithBlock:(void(^)(FBSDKBase64 *base64))block
{
  block([[FBSDKBase64 alloc] initWithOptionsEnabled:YES]);
  block([[FBSDKBase64 alloc] initWithOptionsEnabled:NO]);
}

- (void)runTests:(NSDictionary *)tests
{
  [self runBackwardCompatibilityWithBlock:^(FBSDKBase64 *base64){
    [tests enumerateKeysAndObjectsUsingBlock:^(NSString *plainString, NSString *base64String, BOOL *stop) {
      XCTAssertEqualObjects([base64 encodeString:plainString], base64String);
      XCTAssertEqualObjects([base64 decodeAsString:base64String], plainString);
    }];
  }];
}

- (void)testRFC4648TestVectors
{
  [self runTests:@{
                   @"": @"",
                   @"f": @"Zg==",
                   @"fo": @"Zm8=",
                   @"foo": @"Zm9v",
                   @"foob": @"Zm9vYg==",
                   @"fooba": @"Zm9vYmE=",
                   @"foobar": @"Zm9vYmFy",
                   }];
}

- (void)testDecodeVariations
{
  [self runBackwardCompatibilityWithBlock:^(FBSDKBase64 *base64) {
    XCTAssertEqualObjects([base64 decodeAsString:@"aGVsbG8gd29ybGQh"], @"hello world!");
    XCTAssertEqualObjects([base64 decodeAsString:@"a  GVs\tb\r\nG8gd2\n9y\rbGQ h"], @"hello world!");
    XCTAssertEqualObjects([base64 decodeAsString:@"aGVsbG8gd29ybGQh"], @"hello world!");
    XCTAssertEqualObjects([base64 decodeAsString:@"aGVs#bG8*gd^29yb$GQh"], @"hello world!");
  }];
}

- (void)testEncodeDecode
{
  [self runTests:@{
                   @"Hello World": @"SGVsbG8gV29ybGQ=",
                   @"ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!%^&*(){}[]": @"QUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVoxMjM0NTY3ODkwISVeJiooKXt9W10=",
                   @"\n\t Line with control characters\r\n": @"CgkgTGluZSB3aXRoIGNvbnRyb2wgY2hhcmFjdGVycw0K",
                   }];
}

@end
