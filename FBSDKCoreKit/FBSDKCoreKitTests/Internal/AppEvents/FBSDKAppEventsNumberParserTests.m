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

#import "FBSDKAppEventsNumberParser.h"
#import "FBSDKTestCase.h"

@interface FBSDKAppEventsNumberParserTests : FBSDKTestCase

@end

@implementation FBSDKAppEventsNumberParserTests

- (void)testGetNumberValueDefaultLocale
{
  FBSDKAppEventsNumberParser *parser = [[FBSDKAppEventsNumberParser alloc] initWithLocale:NSLocale.currentLocale];
  NSNumber *result = [parser parseNumberFrom:@"Price: $1,234.56; Buy 1 get 2!"];
  NSString *str = [NSString stringWithFormat:@"%.2f", result.floatValue];
  XCTAssertTrue([str isEqualToString:@"1234.56"]);
}

- (void)testGetNumberValueWithLocaleFR
{
  NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"fr"];
  FBSDKAppEventsNumberParser *parser = [[FBSDKAppEventsNumberParser alloc] initWithLocale:locale];

  NSNumber *result = [parser parseNumberFrom:@"Price: 1\u202F234,56; Buy 1 get 2!"];
  NSString *str = [NSString stringWithFormat:@"%.2f", result.floatValue];
  XCTAssertEqualObjects(str, @"1234.56");
}

- (void)testGetNumberValueWithLocaleIT
{
  NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"it"];
  FBSDKAppEventsNumberParser *parser = [[FBSDKAppEventsNumberParser alloc] initWithLocale:locale];

  NSNumber *result = [parser parseNumberFrom:@"Price: 1.234,56; Buy 1 get 2!"];
  NSString *str = [NSString stringWithFormat:@"%.2f", result.floatValue];
  XCTAssertEqualObjects(str, @"1234.56");
}

@end
