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

#import <XCTest/XCTest.h>

#import "FBSDKCoreKit+Internal.h"

@interface FBSDKUtilityTests : XCTestCase

@end

@implementation FBSDKUtilityTests

- (void)testSHA256Hash {
  NSString *hashed = [FBSDKUtility SHA256Hash:@"facebook"];

  XCTAssertTrue([hashed isEqualToString:@"3d59f7548e1af2151b64135003ce63c0a484c26b9b8b166a7b1c1805ec34b00a"]);
}

- (void)testURLEncode {
  NSString *url = @"https://www.facebook.com/index.html?a=b&c=d";
  NSString *encoded = @"https%3A%2F%2Fwww.facebook.com%2Findex.html%3Fa%3Db%26c%3Dd";
  XCTAssertTrue([encoded isEqualToString:[FBSDKUtility URLEncode:url]]);

  for (int i = 0; i < 256; i++) {
    NSString *str = [NSString stringWithFormat:@"%c", (char)i];
    XCTAssertTrue([[FBSDKUtility URLEncode:str] isEqualToString:[self legacyURLEncode:str]]);
  }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (NSString *)legacyURLEncode:(NSString *)value
{
  return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                               (CFStringRef)value,
                                                                               NULL, // characters to leave unescaped
                                                                               CFSTR(":!*();@/&?+$,='"),
                                                                               kCFStringEncodingUTF8);
}
#pragma clang diagnostic pop

@end
