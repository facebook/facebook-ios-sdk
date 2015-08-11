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

#import <UIKit/UIKit.h>

#import <OCMock/OCMock.h>

#import <XCTest/XCTest.h>

#import "FBSDKMessengerShareOptions.h"
#import "FBSDKMessengerSharer+Internal.h"

@interface FBSDKMessengerShareKitTests : XCTestCase

@end

/**
 * Mock code to parse receiving URL in Messenger
 */
static NSString *unescapeQueryStringPart(NSString *query)
{
  query = [query stringByReplacingOccurrencesOfString:@"+" withString:@" "];
  return [query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

/**
 * Mock code to parse receiving URL in Messenger
 */
static NSDictionary *parseUrlHelper(NSString *urlStr)
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  NSArray *keyValuePairs = [urlStr componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&;"]];
  for (NSString *keyValuePair in keyValuePairs) {
    NSRange equalityRange = [keyValuePair rangeOfString:@"="];
    if (equalityRange.location == NSNotFound) continue;

    NSString *key = unescapeQueryStringPart([keyValuePair substringToIndex:equalityRange.location]);
    NSString *value = unescapeQueryStringPart([keyValuePair substringFromIndex:NSMaxRange(equalityRange)]);

    if (key != nil && value != nil) {
      [dict setObject:value forKeyedSubscript:key];
    }
  }
  return dict;
}

@implementation FBSDKMessengerShareKitTests

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testEscapeSpecialSymbolsInPlatformAppUrl
{
  NSString *metadata = nil;
  NSURL *sourceURL = nil;
  id mock = [OCMockObject mockForClass:[FBSDKMessengerSharer class]];
  [[[[mock expect] classMethod] andReturn:@"20150305"] currentlyInstalledMessengerVersion];


  metadata = @"abc&ef&&??%%_`~-;^";
  sourceURL = [[NSURL alloc] initWithString:@"abc&/*+_-()"];
  [self _URLTester:metadata sourceURL:sourceURL];

  [[[[mock expect] classMethod] andReturn:@"20150305"] currentlyInstalledMessengerVersion];
  metadata = @"   (*%$1#2@3!a~c` d<>?/:;/\n";
  sourceURL = [[NSURL alloc] initWithString:@"123&&&;;;;"];
  [self _URLTester:metadata sourceURL:sourceURL];
}

- (void)_URLTester:(NSString *)metadata sourceURL:(NSURL *)sourceURL
{
  FBSDKMessengerShareOptions *options = [[FBSDKMessengerShareOptions alloc] init];
  options.sourceURL = sourceURL;
  options.metadata = metadata;
  NSURL *url = [FBSDKMessengerSharer _generateUrl:@"com.messenger.image" withOptions:options messengerVersion:@"20150714"];
  NSDictionary *dict = parseUrlHelper(url.query);
  XCTAssertNotNil([dict objectForKey:@"metadata"]);
  XCTAssertTrue([(NSString *)[dict objectForKey:@"metadata"] isEqualToString:metadata]);
  XCTAssertNotNil([dict objectForKey:@"sourceURL"]);
  XCTAssertTrue([(NSString *)[dict objectForKey:@"sourceURL"] isEqualToString:[sourceURL absoluteString]]);
}

@end
